class Conjur::Ldap::Adapter
  class ActiveDirectory < self
    register_adapter_class :active_directory

    def default_user_object_classes
      %w(user posixAccount)
    end

    def default_group_object_classes
      %w(group posixGroup)
    end

    def load_model
      # First collect all groups by their distinguished name.
      # The members attribute of a group lies, so we'll use
      # the user's memberOf instead.
      groups_by_dn = {}
      find_groups.each do |group_branch|
        group = group_from_branch(group_branch)
        groups_by_dn[group.dn] = group
        # TODO incorporate 'members' attribute as well?
      end

      groups = groups_by_dn.values
      users = []
      find_users.each do |user_hash|
        user = user_from_branch(user_hash)
        user_hash['memberOf'].each do |group_dn|
          if group = groups_by_dn[group_dn]
            group << user
          end
        end
        users << user
      end
      model users, groups
    end

    private

    def first_of value
      value ? value.first : nil
    end

    def massage_cn cn
      cn.gsub /\s+/, '_'
    end

    def user_from_branch branch_hash
      uid = branch_hash['uidNumber'].to_i
      cn =  branch_hash[options[:username]]
      dn = branch_hash['distinguishedName']
      user massage_cn(cn), dn, uid
    end

    def group_from_branch branch_hash
      gid = branch_hash['gidNumber'].to_i
      dn = branch_hash['distinguishedName']
      cn  = branch_hash['cn']
      group massage_cn(cn), dn, gid
    end
  end
end
