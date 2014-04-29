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
          conjur.create_role user_role(username)
        end

        target.keys.each do |groupname|
          group = conjur.create_role group_role(groupname)
          target[groupname].each do |username|
            group.grant_to user_role(username)
          end
        end
      end

      def user_role username
        "ldap-user:#{@prefix}/#{username}"
      end

      def group_role groupname
        "ldap-group:#{@prefix}/#{groupname}"
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
