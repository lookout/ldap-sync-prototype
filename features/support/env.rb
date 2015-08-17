require 'aruba/cucumber'
require 'methadone/cucumber'
ENV['PATH'] = "#{File.expand_path(File.dirname(__FILE__) + '/../../bin')}#{File::PATH_SEPARATOR}#{ENV['PATH']}"
LIB_DIR = File.join(File.expand_path(File.dirname(__FILE__)),'..','..','lib')

Before do
  # Using "announce" causes massive warnings on 1.9.2
  @puts = true
  @original_rubylib = ENV['RUBYLIB']
  ENV['RUBYLIB'] = LIB_DIR + File::PATH_SEPARATOR + ENV['RUBYLIB'].to_s
  require 'rspec/mocks/standalone'
end

After do
  ENV['RUBYLIB'] = @original_rubylib
end

dns_pid = spawn('./dns_server', close_others: false)
Process.detach dns_pid

require 'uri'
require 'conjur/cli'
require 'conjur/command/init'
conjur_uri = URI.parse(Conjur.configuration.appliance_url)
fingerprint, certificate = Conjur::Command::Init.get_certificate [ conjur_uri.host, conjur_uri.port ].join(':')
require 'tempfile'
cert_file = Tempfile.new('conjur.pem')
File.write cert_file, certificate
Conjur.configuration.cert_file = cert_file.path
ENV['CONJUR_CERT_FILE'] = cert_file.path

require 'conjur/cli'
require 'conjur/authn'
Conjur::Config.load
Conjur::Config.apply

at_exit do
  Process.kill "HUP", dns_pid
end
