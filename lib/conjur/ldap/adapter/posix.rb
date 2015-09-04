class Conjur::Ldap::Adapter
  class Posix < self
    include Conjur::Ldap::Logging
    register_adapter_class :posix

    def default_user_object_classes
      %w(posixAccount)
    end

    def default_group_object_classes
      %w(posixGroup)
    end

    def load_model
      groups_by_gid = {}
      find_groups.map{|branch| group_from_branch(branch)}.each do |group|
        groups_by_gid[group.gid] = group
      end

      users_by_name = {}
      find_users.map{|branch| user_from_branch(branch)}.each do |user|
        users_by_name[user.name] = user
      end

      log.debug "groups_by_gid=#{groups_by_gid}"
      log.debug "users_by_name=#{users_by_name}"

      groups = groups_by_gid.values
      users  = users_by_name.values

      log.debug "groups before=#{groups.inspect}"
      log.debug "users before=#{users.inspect}"

      # Map members of groups and groups of users onto actual objects.
      # Note that we have to reject! nil members (which can occur if a
      # directory specifies that a user is a member of a non-existant group,
      # for example).

      groups.each do |group|
        group.members.map!{|m| users_by_name[m] }.reject!{|m| m.nil?}
      end

      users.each do |user|
        user.groups.map!{|g| groups_by_gid[g.to_i]}.reject!{|m| m.nil?}
      end

      groups.each do |group|
        group.members.each{|m| m << group}
      end
      users.each do |user|
        user.groups.each{|g| g << user}
      end

      log.debug "users=#{users.inspect}"
      log.debug "groups=#{groups.inspect}"

      model users, groups
    end

    def group_from_branch branch
      name = first_of(branch, 'cn')
      gid  = first_of(branch, 'gidNumber').to_i
      dn   = branch.dn # Not included in the hash
      group(name,dn,gid).tap do |g|
        array_of(branch, 'memberUid').each{|uid| g.members << uid}
      end
    end

    def user_from_branch branch
      name = first_of(branch, 'uid')
      uid  = first_of(branch, 'uidNumber').to_i
      dn   = branch.dn # DN is not included in the entry hash
      user(name, dn, uid).tap do |u|
        array_of(branch, 'gidNumber').each{ |gid| u.groups << gid.to_i }
      end
    end

    private

    def nil_or_empty? v
      v.nil? or (v.respond_to?(:empty?) and v.empty?)
    end

    def attribute branch, name
      val = branch[name]
      if nil_or_empty?(val)
        val = branch[name.downcase]
      end
      raise "missing attribute '#{name}' for object '#{branch.dn}'" if val.nil?
      val
    end

    def first_of branch, name
      val = attribute branch, name
      val.kind_of?(Array) ? val[0] : val
    end

    def array_of branch, name
      val = attribute(branch, name)
      val.is_a?(Array) ? val : [val].compact
    end
  end
end