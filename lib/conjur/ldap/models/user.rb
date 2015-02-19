module Conjur::Ldap
  module Models
    class User < Struct.new(:name, :uid)
      ## Create a User instance from a Treequel::Branch, as returned by
      # Treequel::Directory#children.
      def self.from_branch branch
        e = branch.entry
        User.new e['cn'].first, e['uidNumber'].first.to_i
      end
    end
  end
end