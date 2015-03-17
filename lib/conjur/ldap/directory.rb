require 'treequel/model/objectclass'
require 'patches/treequel'

module Conjur::Ldap::Directory
  module PosixAccount
    extend Treequel::Model::ObjectClass

    model_class Treequel::Model
    model_objectclasses :posixAccount
  end

  module PosixGroup
    extend Treequel::Model::ObjectClass

    model_class Treequel::Model
    model_objectclasses :posixGroup
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

  def posix_groups

    groups_by_gid = {}
    users = []
    PosixGroup.each do |g|
      cn = g.cn.first
      gid = g.gidNumber
      groups_by_gid[gid] = Group.new(cn, gid).tap{|grp| grp.members.concat g.memberUid}
    end

    PosixAccount.each do |u|
      user = User.new u.uid.first, u.uidNumber
      group = groups_by_gid[u.gidNumber]
      users << user
      if group
        group.members << user
        user.groups << group
      end
    end

    Structure.new(groups_by_gid.values, users)
  end
end