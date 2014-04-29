require 'dotenv'
Dotenv.load

require 'active_support/dependencies/autoload'
require 'conjur/api'
require 'securerandom'

module ConjurHelpers
  def mangle_name name
    name.sub '<prefix>', @conjur_prefix
  end
end

conjur = Conjur::API.new_from_key ENV['CONJUR_USERNAME'], ENV['CONJUR_API_KEY']
conjur_prefix = "ldap-sync-" + SecureRandom.urlsafe_base64(8)

include ConjurHelpers
@conjur_prefix = conjur_prefix

conjur.create_role mangle_name('service:<prefix>')
username = mangle_name('service/<prefix>')
key = conjur.create_authn_user(username)['api_key']

ENV['CONJUR_USERNAME'] = username
ENV['CONJUR_API_KEY'] = key

World ConjurHelpers

Before do
  @conjur = conjur
  @conjur_prefix = conjur_prefix
  @aruba_timeout_seconds = 5
end
