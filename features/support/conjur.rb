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
conjur_prefix = SecureRandom.urlsafe_base64 8

include ConjurHelpers
@conjur_prefix = conjur_prefix

conjur.create_role mangle_name('service:<prefix>/ldap')

World ConjurHelpers

Before do
  @conjur = conjur
  @conjur_prefix = conjur_prefix
end
