require 'dotenv'
Dotenv.load

require 'active_support/dependencies/autoload'
require 'conjur/api'
require 'securerandom'

module ConjurHelpers
  BASE_CONJUR = Conjur::API.new_from_key ENV['CONJUR_USERNAME'], ENV['CONJUR_API_KEY']

  def mangle_name name
    name.sub '<prefix>', @conjur_prefix
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
end

World ConjurHelpers

Before do
  init_testrole
  @aruba_timeout_seconds = 13
end
