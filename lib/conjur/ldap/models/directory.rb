module Conjur::Ldap
  module Models
    class Directory < Struct.new :users, :groups

    end
  end
end