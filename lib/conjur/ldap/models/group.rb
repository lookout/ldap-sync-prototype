module Conjur::Ldap
  module Models
    class Group < Struct.new(:name, :gid, :members)
      def self.from_branch branch
        e = branch.entry
        new e['cn'].first, e['gidNumber'].first.to_i, e['memberUid']
      end
    end
  end
end