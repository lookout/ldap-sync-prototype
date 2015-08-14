require 'conjur/api'
require 'conjur/ldap/logging'
require 'conjur/ldap/reporting'
require 'conjur/ldap/reporting/helpers'
require 'conjur/ldap/sync/version'
require 'conjur/ldap/adapter'
require 'conjur/ldap/roles'
require 'patches/treequel'
require 'treequel'
require 'pp'

module Conjur
  module Ldap
    module Sync
      include Conjur::Ldap::Logging
      include Conjur::Ldap::Reporting
      
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
        conjur.sync_to adapter(opts).load_model, opts
      rescue => e
        case e 
          when RestClient::Exception
            log.error "LDAP sync failed: #{e}\n\t#{e.response}"
          else
            log.error "LDAP sync failed: #{e}"
            log.error "backtrace:\n#{$@.join "\n\t"}"
            raise e
        end
      end

      def adapter opts={}
        adapter_opts = opts.reverse_merge(mode: :posix)
          .merge(directory: directory(opts))
        Adapter.for adapter_opts
      end

      def directory opts
        Treequel.directory_from_config.tap do |dir|
          if opts[:bind_dn] and opts[:bind_password]
            dir.bind_as opts[:bind_dn], opts[:bind_password]
          end
        end
      end

      def conjur
        unless @conjur
          Conjur.config.apply_cert_config!
          @conjur = Conjur::API.new_from_key(*conjur_credentials).extend Roles
        end
        @conjur
      end

      # Fetch credentials from environment, returns a [login, password] pair
      def conjur_credentials
        api_key = ENV['CONJUR_API_KEY'] or raise("Missing $CONJUR_API_KEY")
        login = ENV['CONJUR_USERNAME'] or ENV['CONJUR_AUTHN_LOGIN'] or raise("You must provide $CONJUR_USERNAME or $CONJUR_AUTHN_LOGIN")
        [login, api_key]
      end
    end
  end
end
