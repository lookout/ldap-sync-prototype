require 'treequel/model/objectclass'
require 'patches/treequel'

module Conjur::Ldap::Directory
  module PosixAccount
    extend Treequel::Model::ObjectClass

    model_class Treequel::Model
    model_objectclasses :user
  end

  module PosixGroup
    extend Treequel::Model::ObjectClass

    model_class Treequel::Model
    model_objectclasses :group
  end

  Group = Struct.new(:name, :gid) do
    def members
      @members ||= []
    end
  end

  User = Struct.new(:name, :uid) do
    def groups
      @groups ||= []
    end
  end

  Structure = Struct.new(:groups, :users)

  def first_of value
    value ? value.first : nil
  end

  def massage_cn cn
    cn.gsub /\s+/, '_'
  end

  def user_from_branch branch_hash
    uid = branch_hash['uidNumber'].to_i
    cn =  branch_hash['cn']
    User.new(massage_cn(cn), uid)
  end

  def group_from_branch branch_hash
    gid = branch_hash['gidNumber']
    dn = branch_hash['distinguishedName']
    cn  = branch_hash['cn']
    [dn, Group.new(massage_cn(cn), gid)]
  end

  def posix_groups
    # First collect all groups by their distinguished name.
    # The members attribute of a group lies, so we'll use
    # the user's memberOf instead.
    groups_by_dn = {}
    find_groups.each do |group_branch|
      dn, group = group_from_branch(group_branch)
      groups_by_dn[dn] = group
    end

    groups = groups_by_dn.values
    users = []
    find_users.each do |user_hash|
      user = user_from_branch(user_hash)
      user_hash['memberOf'].each do |group_dn|
        if group = groups_by_dn[group_dn]
          user.groups << group
          group.members << user
        end
      end
      users << user
    end
    Structure.new(groups, users)
  end

  def find_users
    search base_dn, :subtree, '(objectClass=user)'
  end

  def find_groups
    search base_dn, :subtree, '(objectClass=group)'
  end
end