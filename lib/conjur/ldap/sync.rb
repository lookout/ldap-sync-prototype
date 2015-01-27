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

      # Entry point for sync operation
      #
      # @param opts [Hash] options for sync behavior
      # @option opts [String] :owner (logged in conjur user) the role that will own
      #   all created assets.
      # @option opts [String] :prefix (created from owner) prefix to namespace created assets
      # @option opts [Boolean] :save_passwords (false) whether to save credentials for users created
      #   in variables.
      def run_sync opts
        conjur.sync_to directory.posix_groups, opts
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
