require 'conjur/api'
require 'conjur/ldap/sync/version'
require 'conjur/ldap/directory'
require 'treequel'
require 'pp'

module Conjur
  module Ldap
    module Sync
      module_function

      def run_sync
        directory = Treequel.directory_from_config

        directory.extend Directory
        target = directory.posix_groups

        target.values.flatten.uniq.each do |username|
          conjur.create_role "ldap-user:#{@prefix}/#{username}"
        end
      end

      def conjur
        unless @conjur
          username = ENV['CONJUR_USERNAME']
          @conjur = Conjur::API.new_from_key username, ENV['CONJUR_API_KEY']
          @prefix = username.remove /.*\//
        end
        @conjur
      end
    end
  end
end
