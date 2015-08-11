module Conjur::Ldap
  class Adapter

    class << self
      # Creates a new adapter for the given options
      #
      # The hash given must contain a :mode member, which is the name of
      # the adapter to use (:posix or :active_directory, currently).
      #
      # Remaining options in the hash are passed to the adapter's constructor
      def for opts
        mode = opts[:mode] || raise('Missing :mode option!')
        self[mode].new opts.reject{|k| k == :mode}
      end

      def [] mode
        mode = mode.to_sym
        adapter_classes[mode] || missing_adapter!
      end

      def []= mode, klass
        adapter_classes[mode.to_sym] = klass
      end

      def register_adapter_class name
        Conjur::Ldap::Adapter.adapter_classes[name] = self
      end

      def adapter_classes
        @adapter_classes ||= {}
      end

      def missing_adapter! mode
        raise "Unknown mode '#{mode}': valid modes are #{adapter_classes.keys.join(', ')}"
      end
    end

    class Model < Struct.new(:users,:groups); end

    class User < Struct.new(:name, :dn, :uid)
      def groups
        @groups ||= Set.new
      end

      def << group
        groups << group
        group.members << self
      end

      def add_groups groups
        self.groups += groups
        groups.each{|group| group.members << self}
      end
    end

    class Group < Struct.new(:name, :dn, :gid)
      def members
        @members ||= Set.new
      end

      def << member
        members << member
        member.groups << self
      end

      def add_members members
        self.members += members
        members.each{|user| user.groups << self}
      end
    end

    attr_reader :options

    attr_reader :directory


    def initialize options={}
      @options = options
      @directory = options[:directory] || Treequel.directory_from_config
    end

    def user name, dn, uid=nil
      User.new(name, dn, uid)
    end

    def group name, dn, gid=nil
      Group.new name, dn, gid
    end

    def model users, groups
      Model.new users, groups
    end

    def group_object_classes
      options[:group_object_classes] || default_group_object_classes
    end

    def user_object_classes
      options[:user_object_classes] || default_user_object_classes
    end

    def find_groups
      directory.search directory.base_dn, :subtree, groups_filter
    end

    def find_users
      directory.search directory.base_dn, :subtree, users_filter
    end

    def groups_filter
      object_class_filter group_object_classes
    end

    def users_filter
      object_class_filter user_object_classes
    end

    def object_class_filter object_classes
      Treequel::Filter.new(objectClass: object_classes).to_s
    end

    # Subclasses must implement this to return an Array of
    # objectClasses used to mark users that should be imported.
    #
    # This is overridden by the --user-object-classes flag/env var.
    #
    # @return [Array<String>] the object classes
    def default_user_object_classes
      raise NotImplementedError, '#default_user_object_classes is abstract'
    end

    # Subclasses must implement this to return an Array of objectClasses
    # used to mark groups that should be imported.
    #
    # This is overridden by the --group-object-classes flag/env var
    #
    # @return [Array<String>] the objectClasses
    def default_group_object_classes
      raise NotImplementedError, '#default_group_object_classes is abstract'
    end

    # Subclasses must implement this to retrieve groups and
    # users from the LDAP server.
    #
    # @return [Conjur::Ldap::Adapter::Model] the users and groups
    def load_model
      raise NotImplementedError, '#load is abstract'
    end

  end
end

# Hack, just require everything under '__FILE__/../adapter'
path = File.join(File.dirname(__FILE__), 'adapter')
Dir[path + '/*.rb'].each{|f| load(f)}