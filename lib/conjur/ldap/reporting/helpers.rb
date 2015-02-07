module Conjur::Ldap::Reporting
  module Helpers
    def self.helper_method tag, *arg_keys
      method_name = :"report_#{tag}"
      make_exras = ->(*args) {
        args.zip(arg_keys).inject({}){|h, p|  h[p[1]] = p[0]; h}
      }

      define_method method_name do |*args, &block|
        extras = make_exras[*args]
        report tag, extras, &block
      end
    end

    helper_method :create_user, :user, :uid
    helper_method :create_group, :group, :gid
    helper_method :update_user, :user, :uid
    helper_method :update_group, :group, :gid
    helper_method :add_member, :group, :user
    helper_method :remove_member, :group, :user
    helper_method :save_api_key, :user, :variable
  end
end