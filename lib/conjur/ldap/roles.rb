# A mixin for Conjur::API implementing utility functions
# for role manipulation used in ldap-sync.
class Conjur::Ldap::Roles
  # Constants for annotations
  SOURCE_KEY = 'ldap-sync/source'
  UPSTREAM_DN_KEY = 'ldap-sync/upstream-dn'


  include Conjur::Ldap::Logging
  include Conjur::Ldap::Reporting
  include Conjur::Ldap::Reporting::Helpers

  def initialize conjur_api, opts
    @api = conjur_api
    @options = opts
  end


  # Modifies LDAP roles in Conjur to reflect the given LDAP structure
  # 
  # LDAP groups are mapped to Conjur groups, and LDAP users to Conjur 
  # users.  Their names are preserved as-is, and their uidnumber and gidnumber
  # are set from the LDAP gidNumber and uidNumber.
  # 
  # Because you can't delete roles Conjur, any roles that are
  # deleted in upstream are simply removed from all membership relations
  # that were created by the tool.
  #
  # Thus, if you add a user imported from LDAP to a group that was *not* imported
  # from LDAP, the user will remain in that group.  This also prevents important roles
  # such as the owner (or the role as which the ldap-sync tool runs).
  #
  #
  #
  #
  # @param [Conjur::Ldap::Directory::Structure] target structure of the LDAP directory
  # @param [Hash] opts
  # @option opts [String] :owner (logged in conjur user) the role that will own
  #   all created assets.
  # @option opts [String] :prefix (created from owner) prefix to namespace created assets
  # @option opts [Boolean] :save_api_keys (false) whether to save credentials for users created
  #   in variables.
  # @option opts [Boolean] :import_ldap_ids (true) whether to import uids and gids from LDAP
  #   This should not generally be set to false, but it gives an 'escape hatch' to allow import
  #   in the face of collisions with existing Conjur roles.
  def sync_to target
    @target  = target
    @options = normalize_options(@options) unless @options.frozen?
    # Add/update ldap users
    ldap_users.each do |ldap_user|
      process_ldap_user(ldap_user)
    end

    # Add/update ldap groups
    ldap_groups.each do |ldap_group|
      process_ldap_group(ldap_group)
    end
  end



  # Default value for our asset prefix, generated from the conjur username
  #   of the current role.
  # @return [String]
  def default_prefix
    username.remove /^.*\//
  end

  # Finds the owner role.  The role must exist and be a member of current_role
  # @return Conjur::Role
  def find_role id_or_role
    api.role(id_or_role).tap do |role|
      raise "Role #{id_or_role} does not exist!" unless role.exists?
      raise "Role #{current_role.roleid} is not a member of #{id_or_role}" unless api.current_role.member_of?(role)
    end
  end

  def process_ldap_user ldap_user
    # Find an existing user or create one.
    username = prefixed ldap_user.name

    uid = ldap_user.uid.nil? ? nil : ldap_user.uid.to_i # it SHOULD be an int, but just be defensive...

    conjur_user = api.user(username)

    # the exists? call isn't cached, so we'll retain the result
    exists = conjur_user.exists?

    # Update the uid number if necessary
    if exists and not (ignore_ldap_ids? or uid.nil? or uid == conjur_user.attributes['uidnumber'])
      update_conjur_user conjur_user, uid
    end

    # If it doesn't exist, create it.
    unless exists
      conjur_user = create_conjur_user username, uid, ldap_user
    end

    remove_user_from_groups conjur_user, ldap_user.groups
  end

  def process_ldap_group ldap_group
    groupname = prefixed(ldap_group.name)
    gid = ldap_group.gid.nil? ? nil : ldap_group.gid.to_i

    conjur_group = api.group(groupname)

    exists = conjur_group.exists?

    if exists &&  !(ignore_ldap_ids? ||
        gid.nil? ||
        gid == conjur_group.attributes['gidnumber'])
      update_conjur_group conjur_group, gid
    end

    unless exists
      conjur_group = create_conjur_group groupname, gid, ldap_group
    end

    remove_members_from_group conjur_group, ldap_group.members
    add_members_to_group conjur_group, ldap_group.members
  end

  # Updates `conjur_user` to have `uid`.  This method makes a number of assumptions
  # that are validated in the process_ldap_user method.
  def update_conjur_user conjur_user, uid
    report :update_user, user: conjur_user.id, uid: uid do
      conjur_user.update uidnumber: uid
    end
  end

  # Analogous to `update_conjur_user`
  def update_conjur_group conjur_group, gid
    report :update_group, group: conjur_group.id, gid: gid do
      conjur_group.update gidnumber: gid
    end
  end

  # Creates a Conjur user, assigning them a password saved in a variable if
  # the save_api_keys? option is present.
  def create_conjur_user username, uid, ldap_user
    opts = {ownerid: owner.roleid}
    opts.merge!(uidnumber: uid) unless uid.nil? or ignore_ldap_ids?
    report :create_user, user: username, uid: uid do
      api.create_user(username, opts).tap do |conjur_user|
        save_user_api_key(conjur_user) if save_api_keys?
        add_marker_annotations(conjur_user, ldap_user)
      end
    end
  end

  # Analogous to `create_conjur_user`
  def create_conjur_group groupname, gid, ldap_group
    opts = {ownerid: owner.roleid}
    opts.merge!(gidnumber: gid) unless gid.nil? or ignore_ldap_ids?
    report :create_group, group: groupname, gid: gid do
      api.create_group(groupname, opts).tap do |conjur_group|
        add_marker_annotations(conjur_group, ldap_group)
      end
    end
  end

  def save_user_api_key conjur_user
    variable_id = "#{conjur_user.login}/api-key"
    report :save_api_key, username: conjur_user.login, variable_id: variable_id do
      api.create_variable('text/plain',
          'conjur-api-key',
          id: variable_id,
          ownerid: owner.roleid).add_value conjur_user.api_key
    end
  end

  def add_marker_annotations asset, ldap_asset
    asset.resource.annotations.merge!(
        SOURCE_KEY => marker_tag,
        UPSTREAM_DN_KEY => ldap_asset.dn
    )
  end

  def remove_user_from_groups conjur_user, ldap_groups
    # Check to see if the user is a member of any of "our" groups that
    # are not present in ldap_groups.  Remove the user from any such groups.
    remove_from = conjur_user.role.memberships.select do |role|
      role.kind == 'group' &&
          from_ldap?(role.roleid) &&
          ldap_groups.find{|g| prefixed(g.name) == role.id}.nil?
    end

    remove_from.each do |conjur_role|
      report :remove_member, group: conjur_role.id, user: conjur_user.login do
        conjur_role.revoke_from conjur_user.role
      end
    end
  end

  # Note that this is only called on *existing* groups, so we needn't
  # worry about trying to avoid repeating actions taken by remove_user_from_groups
  def remove_members_from_group conjur_group, ldap_users
    remove_members = conjur_group.role.members.map(&:member).select do |role|
      role.kind == 'user' &&
          from_ldap?(role.roleid) &&
          ldap_users.find{|u| prefixed(u.name) == role.id}.nil?
    end

    remove_members.each do |conjur_role|
      report :remove_member, group: conjur_group.id, user: conjur_role.id do
        conjur_group.remove_member self.user(conjur_role.id)
      end
    end
  end

  def add_members_to_group conjur_group, ldap_users
    ldap_users.map{|u| prefixed(u.name)}.each do |username|
      # TODO we should really cache this call to members
      next if is_member_of_group?(conjur_group.id, username)
      report :add_member, user: username, group: conjur_group.id do
        conjur_user = api.user(username)
        conjur_group.add_member conjur_user
      end
    end
  end

  # Is this conjur id from 'our' ldap source?
  # Note that we return false if a resource with the conjur id doesn't exist.
  # I'm not sure that this is correct behavior - jjmason
  def from_ldap? conjur_id
    resource = api.resource conjur_id
    resource.exists? and resource.annotations[SOURCE_KEY] == marker_tag
  end

  def is_member_of_group? group_id, user_id
    not api.group(group_id).role.members.map(&:member)
        .find{|m| m.id == user_id }.nil?
  end

  ##
  # Helper Methods
  ##

  def full_user_id username
    [Conjur.configuration.account, 'user', username].join ':'
  end

  def prefixed name
    if prefix and not prefix.empty?
      "#{prefix}-#{name}"
    else
      name
    end
  end


  # @!attribute r frozen hash containing our options.
  attr_reader :options

  attr_reader :api

  def prefix; options[:prefix] end
  def owner; options[:owner] end
  def save_api_keys?; options[:save_api_keys] end
  def ignore_ldap_ids?; options[:ignore_ldap_ids] end
  def marker_tag
    options[:marker_tag] || api.current_role.roleid
  end
  private

  # Normalize options given to #sync_to.
  def normalize_options opts
    opts[:owner] = find_role(opts[:owner] || api.current_role)
    {save_api_keys: false, import_ldap_ids: true}.merge(opts).freeze
  end

  # Resources marked with the tag we are currently using
  def tagged_resources
    @tagged_resources ||= resources(search: marker_tag).select do |resource|
      resource.annotations[SOURCE_KEY] == marker_tag
    end
  end

  def tagged_users
    @tagged_users ||= tagged_resources.select{|r| r.kind == 'user'}
        .map{|r| user(r.identifier)}
  end

  def tagged_groups
    @tagged_groups ||= tagged_resources.select{|r| r.kind == 'group'}
        .map{|r| group(r.identifier)}
  end

  def ldap_users
    @target.users
  end

  def ldap_groups
    @target.groups
  end

end
