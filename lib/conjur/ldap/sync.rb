require 'conjur/api'
require 'conjur/ldap/sync/version'
require 'conjur/ldap/directory'
require 'conjur/ldap/roles'
require 'treequel'
require 'pp'

module Conjur
  module Ldap
    module Sync
      module_function

      def run_sync
        conjur.sync_to directory.posix_groups
      end

      def directory
        unless @directory
          @directory = Treequel.directory_from_config
          @directory.extend Directory
        end
        @directory
      end

      def conjur
        unless @conjur
          @conjur = Conjur::API.new_from_key ENV['CONJUR_USERNAME'], ENV['CONJUR_API_KEY']
          @conjur.extend Roles
        end
        @conjur
      end
    end
  end
end
