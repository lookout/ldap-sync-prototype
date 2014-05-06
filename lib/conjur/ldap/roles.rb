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
  def sync_to target
    target.values.flatten.uniq.each do |username|
      create_role user_role(username)
    end

    target.keys.each do |groupname|
      group = create_role group_role(groupname)
      target[groupname].each do |username|
        group.grant_to user_role(username)
      end
    end
  end

  # @return [String] a role id corresponding to LDAP +username+.
  def user_role username
    "ldap-user:#{prefix}/#{username}"
  end

  # @return [String] a role id corresponding to LDAP +groupname+.
  def group_role groupname
    "ldap-group:#{prefix}/#{groupname}"
  end

  # @return [String] the prefix for the ids of managed roles.
  def prefix
    @prefix ||= username.remove /^.*\//
  end
end
