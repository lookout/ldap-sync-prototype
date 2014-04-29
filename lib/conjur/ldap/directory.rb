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

  def posix_groups
    gids = {}
    groups = {}

    PosixGroup.each do |g|
      cn = g.cn.first
      gids[g.gidNumber] = cn
      groups[cn] = g.memberUid
    end

    PosixAccount.each do |u|
      groups[gids[u.gidNumber]] += u.uid
    end

    groups
  end
end
