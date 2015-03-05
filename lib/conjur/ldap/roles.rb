# A mixin for Conjur::API implementing utility functions
# for role manipulation used in ldap-sync.

module Conjur::Ldap::Roles
  include Conjur::Ldap::Logging
  include Conjur::Ldap::Reporting
  include Conjur::Ldap::Reporting::Helpers
  # Modifies LDAP roles in Conjur to reflect the given LDAP structure
  # 
  # LDAP groups are mapped to Conjur groups, and LDAP users to Conjur 
  # users.  Their names are preserved as-is, and their uidnumber and gidnumber
  # are set from the LDAP gidNumber and uidNumber.
  # 
  # Because you can't delete roles Conjur, any roles that are
  # deleted in upstream are simply removed from all membership relations
  # (except the admin one).
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
  def sync_to target, opts
    @options = normalize_options opts
    users = target.users
    groups = target.groups
    
    # First make sure that all of the user roles exist.
    users.each{|u| find_or_create_user(prefixed(u.name), u.uid)}
    
    groups.each do |g|
      group = find_or_create_group prefixed(g.name), g.gid
      update_group_memberships(group, g.members.map{ |m| m.name rescue m }) unless group.nil?
    end
  end

  # @!attribute r frozen hash containing our options.
  attr_reader :options

  def prefix; options[:prefix] end
  def owner; options[:owner] end
  def save_api_keys?; options[:save_api_keys] end
  def ignore_ldap_ids?; options[:ignore_ldap_ids] end

  private

  # Normalize options given to #sync_to.
  def normalize_options opts
    opts[:owner] = find_role(opts[:owner] || current_role)
    {save_api_keys: false, import_ldap_ids: true}.merge(opts).freeze
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
    self.role(id_or_role).tap do |role|
      raise "Role #{id_or_role} does not exist!" unless role.exists?
      raise "Role #{current_role.roleid} is not a member of #{id_or_role}" unless current_role.member_of?(role)
    end
  end

  # Find or create a Conjur user corresponding to the LDAP user
  #
  # @param [String] username the LDAP username
  # @param [String, Fixnum] uid the LDAP uidNumber
  # @return [Conjur::User] the user
  def find_or_create_user username, uid
    uid = uid.to_i
    user = self.user(username)
    if user.exists?
      report_update_user(username, uid){ user.update uidnumber: uid} if not ignore_ldap_ids? and user.attributes['uidnumber'] != uid
    else
      opts = {ownerid: owner.roleid}
      opts = opts.merge(uidnumber: uid) unless ignore_ldap_ids?
      user = report_create_user(username, uid){ create_user username, opts}
      if user and save_api_keys?
        variable = user_password_variable(user)
        report_save_api_key(username,variable.id){ variable.add_value user.api_key }
      end
    end
    user
  end

  def find_or_create_group groupname, gid
    gid = gid.to_i
    group = self.group(groupname)
    if group.exists?
      report_update_group(groupname, gid){group.update(gidnumber: gid)} if not ignore_ldap_ids? and group.attributes['gidnumber'] != gid
    else
      opts = {ownerid: owner.roleid}
      opts = opts.merge(gidnumber: gid) unless ignore_ldap_ids?
      group = report_create_group(groupname, gid){ create_group groupname, opts }
    end
    group
  end

  
  # Update conjur group members to match the current LDAP groups
  # @param [Conjur::Group] group
  # @param [Array<String>] usernames
  def update_group_memberships group, usernames
    members = group.role.members.reject{|grant| grant.member.kind != 'user'}.map{|grant| grant.member.identifier}

    usernames.map{|u| prefixed(u)}.each do |username|
      if members.member?(username)
        members.delete(username)
      else
        report_add_member(group.id, username){ group.add_member full_user_id(username) }
      end
    end

    members.each do |member|
      report_remove_member(group.id, member){ group.remove_member(full_user_id(member)) }
    end
  end

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

  def user_password_variable user
    create_variable 'text/plain', 'conjur-api-key', id: "#{user.login}/api-key", ownerid: owner.roleid
  end

end
