# A mixin for Conjur::API implementing utility functions
# for role manipulation used in ldap-sync.

module Conjur::Ldap::Roles
  # Modifies LDAP roles in Conjur to reflect given target hash.
  #
  # Keys in the given hash are understood to represent user group (names);
  # the corresponding values should be string arrays of user names.
  #
  # Groups are created as +ldap-group+ roles and users as +ldap-group+.
  # If a hierarchy already exists, it is adjusted to the target by changing
  # corresponding role memberships.
  #
  # Because it's not allowed to delete roles in Conjur, any roles that are
  # deleted in upstream are simply removed from all membership relations
  # (except the admin one).
  #
  # @param [Hash] target role hierarchy.
  # @param [Hash] opts
  # @option opts [String] :owner (logged in conjur user) the role that will own
  #   all created assets.
  # @option opts [String] :prefix (created from owner) prefix to namespace created assets
  # @option opts [Boolean] :save_passwords (false) whether to save credentials for users created
  #   in variables.
  # @option opts [String] :ldap_agent_role when given, all created roles will be granted to this role.
  def sync_to target, opts
    @options = normalize_options opts

    # First make sure that all of the user roles exist.
    target.values.flatten.uniq.each do |username|
      find_or_create_user username
    end

    # Now create the groups
    target.each do |groupname, usernames|
      update_group_memberships find_or_create_group(groupname), usernames
    end

    # Finally, add the roles to the ldap-agent role if given
    if ldap_agent_role
      new_roles.each do |role|
        role.grant_to ldap_agent_role
      end
    end
  end

  # @!attribute r frozen hash containing our options.
  attr_reader :options

  def prefix; options[:prefix] end
  def owner; options[:owner] end
  def save_passwords?; options[:save_passwords] end
  def ldap_agent_role; options[:ldap_agent_role] end

  def new_roles
    @new_roles ||= []
  end


  private

  # Normalize options given to #sync_to.
  def normalize_options opts
     opts.slice(:owner,:prefix, :save_passwords)
         .reverse_merge(save_passwords: false,
                        prefix: default_prefix)
    opts[:owner] = find_role(opts[:owner] || current_role)
    opts[:ldap_agent_role] = find_role(opts[:owner]) if opts[:ldap_agent_role]
    opts.freeze
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
      raise "Role #{id_or_role} does not exist!" unless role.exists?
    end
  end

  # Find or create a Conjur user corresponding to the LDAP user
  #
  # @param [String] username the LDAP username
  # @return [Conjur::User] the user
  def find_or_create_user username
    find_or_create :user, username, owner: owner.roleid, password: false do |user|
      save_user_password(user) if save_passwords?
    end
  end

  def find_or_create_group groupname
    find_or_create :group, groupname, owner: owner.roleid
  end


  def find_or_create kind, id,opts = {}
    role_name = send(:"ldap_#{kind}", id)
    role = send(kind.to_sym)
    unless role.exists?
      role = send(:"create_#{kind}", role_name, opts)
      new_roles << role.role
      yield role if block_given?
    end
    role
  end

  def save_user_password user
    password = user.password || user.api_key
    user_password_variable(user).add_value(user.api_key)
  end

  # Update conjur group members to match the current LDAP groups
  # @param [Conjur::Group] group
  # @param [Array<String>] usernames
  def update_group_memberships group, usernames
    members = group.role.members.reject{|grant| grant.member.kind != 'user'}.map{|grant| grant.member.identifier}

    usernames.map{|u| ldap_user(u)}.each do |username|
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

  # TODO refactor
  # Create a namespaced ldap username
  def ldap_user username
    prefixed username
  end

  def full_user_id username
    [Conjur.configuration.account, 'user', username].join ':'
  end

  def ldap_group groupname
    prefixed groupname
  end

  def prefixed name
    "#{(prefix.nil? || prefix.empty?) ? 'ldap' : prefix}/#{name}"
  end

  def user_password_variable user
    create_variable 'text/plain', 'conjur-api-key', "#{prefix}/#{user.login}/password"
  end

end
