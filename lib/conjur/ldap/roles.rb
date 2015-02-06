# A mixin for Conjur::API implementing utility functions
# for role manipulation used in ldap-sync.

module Conjur::Ldap::Roles
  include Conjur::Ldap::Logging
  
  # Modifies LDAP roles in Conjur to reflect give  LDAP structure
  # 
  # LDAP groups are mapped to Conjur groups, and LDAP users to Conjur 
  # users.  Their names are preserved as-is, and their uidnumber and gidnumber
  # are set from the LDAP gidNumber and uidNumber fields in LDAP.
  # 
  # Because it's not allowed to delete roles in Conjur, any roles that are
  # deleted in upstream are simply removed from all membership relations
  # (except the admin one).
  #
  # @param [Conjur::Ldap::Directory::Structure] target structure of the LDAP directory
  # @param [Hash] opts
  # @option opts [String] :owner (logged in conjur user) the role that will own
  #   all created assets.
  # @option opts [String] :prefix (created from owner) prefix to namespace created assets
  # @option opts [Boolean] :save_passwords (false) whether to save credentials for users created
  #   in variables.
  def sync_to target, opts
    @options = normalize_options opts
    
    logger.debug "self.prefix=#{prefix}"
    logger.debug "groups=#{target.groups}, #{target.users}"
    
    users = target.users
    groups = target.groups
    
    # First make sure that all of the user roles exist.
    users.each{|u| find_or_create_user(prefixed(u.name), u.uid)}
    
    groups.each do |g|
      group = find_or_create_group prefixed(g.name), g.gid
      update_group_memberships group, g.members.map{ |m| m.name rescue m } # WTF sometimes members are strings, sometimes User objects???
    end
  end

  # @!attribute r frozen hash containing our options.
  attr_reader :options

  def prefix; options[:prefix] end
  def owner; options[:owner] end
  def save_passwords?; options[:save_passwords] end

  private

  # Normalize options given to #sync_to.
  def normalize_options opts
    opts[:owner] = find_role(opts[:owner] || current_role)
    opts.freeze
    opts
  end

  # Default value for our asset prefix, generated from the conjur username
  #   of the current role.
  # @return [String]
  def default_prefix
    username.remove /^.*\//
  end

  # Finds the owner role
  # @return Conjur::Role
  def find_role id_or_role
    self.role(id_or_role).tap do |role|
      logger.debug "looking up role #{role}"
      raise "Role #{id_or_role} does not exist!" unless role.exists?
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
    log.debug "find_or_create_user #{username}, #{uid}"
    if user.exists? # TODO also check for ownership
      user.update uidnumber: uid
    else
      user = create_user username, uidnumber: uid, ownerid: owner.roleid
      if save_passwords?
        user_password_variable(user).add_value user.api_key
      end
    end
    user
  end

  def find_or_create_group groupname, gid
    gid = gid.to_i
    group = self.group(groupname)
    logger.debug{ "checking for existence of #{groupname}: #{group.exists?}" }
    if group.exists?
      group.update(gidnumber: gid) unless gid == group.attributes['gidnumber']
    else
      group = create_group groupname, gidnumber: gid, ownerid: owner.roleid
      logger.debug{ "created group #{groupname} with gid #{gid}" }
    end
    group
  end

  def save_user_password user
    password = user.password || user.api_key
    user_password_variable(user).add_value(password)
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
        group.add_member full_user_id(username)
      end
    end

    members.each do |member|
      group.remove_member(full_user_id(member))
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
    logger.debug{ "creating password in variable '#{user.login}/api-key'" }
    create_variable 'text/plain', 'conjur-api-key', id: "#{user.login}/api-key", ownerid: owner.roleid
  end

end
