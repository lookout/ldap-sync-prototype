require 'dotenv'
Dotenv.load

require 'active_support/dependencies/autoload'
require 'conjur/api'
require 'securerandom'

module ConjurHelpers
  Conjur.configuration.account = ENV['CONJUR_ACCOUNT'] || 'ci'

  BASE_CONJUR = Conjur::API.new_from_key(
      ENV['CONJUR_USERNAME'] || ENV['CONJUR_AUTHN_LOGIN'],
      ENV['CONJUR_API_KEY'])

  attr_reader :conjur
  attr_reader :conjur_prefix
  attr_reader :service_role

  def mangle_name name
    name.gsub /<prefix>/, @conjur_prefix
  end

  def conjur_account
    Conjur.configuration.account
  end

  def roles_by_name
    @roles_by_name ||= {}
  end

  def init_testrole
    @conjur_prefix = "ldap-sync-" + SecureRandom.urlsafe_base64(8)
    username = mangle_name('service/<prefix>')

    @service_role = BASE_CONJUR.create_role mangle_name('service:<prefix>')
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

  def expected_actions_from_table table
    table = table.hashes unless table.kind_of?(Array)
    [].tap do |result|
      table.each do |hash|
        extra = insert_uids mangle_name(hash['extra_json'])
        extra = extra.empty? ? {} : JSON.parse(extra)
        result << {'tag' => hash['tag']}.merge(extra)
      end
    end
  end

  def match_action expected, actual
    expected.each do |key, value|
      expect(value).to eq(actual[key])
    end
  end

end

World ConjurHelpers

Before do
  init_testrole
  @aruba_timeout_seconds = 600 # 10 minutes
end
