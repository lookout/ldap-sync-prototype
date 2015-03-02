require 'treequel'
require 'conjur/ldap/driver'


## A driver that handles Conjur LDAP's idiosyncrasies
class Conjur::Ldap::Driver
  class Conjur < self
    attr_reader :conjur_account, :host_id, :host_api_key

    def initialize options
      [:conjur_accoun, :host_id, :host_api_key].each do |opt|
        raise ArgumentError, "missing required option #{opt}" unless options.member?(opt)
        instance_variable_set :"@#{opt}", options[opt]
      end
    end

    def groups
      build_groups directories['group'].children
    end

    def users
      build_users directories['user'].children
    end

    private

    def build_groups branches
      branches.map{|b| Conjur::Ldap::Model::Group.from_branch(b)}
    end

    def build_users branches
      branches.map{|b| Conjur::Ldap::Model::User.from_branch(b)}
    end

    def directories
      @directories ||= Hash.new do |h, k|
        h[k] = create_directory k
      end
    end

    def create_directory ou
      Treequel.directory_from_config.tap do |dir|
        dir.base_dn = base_dn(ou)
        dir.bind bind_dn, host_api_key
      end
    end

    def base_dn ou
      "ou=#{ou},host=#{host_id},account=#{conjur_account},o=conjur"
    end

    def bind_dn
      "ou=host,uid=#{host_id},host=#{host_id},account=#{conjur_account},o=conjur"
    end
  end
end