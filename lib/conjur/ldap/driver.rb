require 'conjur/ldap/models/group'
require 'conjur/ldap/models/user'
require 'conjur/ldap/models/directory'

module Conjur::Ldap
  ##
  # Abstract base class for drivers.  A Driver subclass knows how
  # to configure itself to connect to a particular LDAP setup and
  # fetch posixGroups and posixObjects.
  class Driver

    ## Fetches a list of Conjur::Ldap::Model::Group objects whose
    #  members are Conjur::Ldap::User objects.  You won't normally override this.
    def fetch
      groups, users = self.groups, self.users
      users_by_name = users.inject({}){|h,u| h[u.name] = u; h}
      groups.each do |group|
        group.members = group.members.map do |user_name|
          users_by_name[user_name]
        end.compact
      end
      Conjur::Ldap::Models::Directory.new users, groups
    end


    # Subclasses implement this method to return can array of Conjur::Ldap::Model::Group
    # whose members may be user.name strings.
    #
    # @api private
    # @abstract
    # @return [Array<Conjur::Ldap::Model::Group>]
    def groups
      raise NotImplemented, "Driver#groups is abstract"
    end

    # Subclasses implement this to return an array of Conjur::Ldap::Model::User.
    #
    # @abstract
    # @api private
    # @return [Array<Conjur::Ldap::Model::User>]
    def users
      raise NotImplemented, "Driver#groups is abstract"
    end
  end
end