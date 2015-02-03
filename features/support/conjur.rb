require 'dotenv'
Dotenv.load

require 'active_support/dependencies/autoload'
require 'conjur/api'
require 'securerandom'

module ConjurHelpers
  BASE_CONJUR = Conjur::API.new_from_key ENV['CONJUR_USERNAME'], ENV['CONJUR_API_KEY']

  attr_reader :conjur
  attr_reader :conjur_prefix

  def mangle_name name
    name.gsub /<prefix>/, @conjur_prefix
  end

  def roles_by_name
    @roles_by_name ||= {}
  end

  def init_testrole
    @conjur_prefix = "ldap-sync-" + SecureRandom.urlsafe_base64(8)
    username = mangle_name('service/<prefix>')

    BASE_CONJUR.create_role mangle_name('service:<prefix>')
    key = BASE_CONJUR.create_authn_user(username)['api_key']

    @conjur = Conjur::API.new_from_key username, key

    ENV['CONJUR_USERNAME'] = username
    ENV['CONJUR_API_KEY'] = key
  end

  def find_or_create_role rolename
    mangled = mangle_name(rolename)
    unless (role = conjur.role(mangled)).exists?
      role = conjur.create_role(mangled)
    end
    role
  end

  attr_writer :run_sync_opts
  def run_sync_opts; @run_sync_opts ||= {} end
  attr_accessor :run_sync_called
  alias run_sync_called? run_sync_called

end

World ConjurHelpers

Before do
  init_testrole
  @aruba_timeout_seconds = 13
end
