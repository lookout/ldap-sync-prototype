# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'conjur/ldap/sync/version'

Gem::Specification.new do |spec|
  spec.name          = "conjur-ldap-sync"
  spec.version       = Conjur::Ldap::Sync::VERSION
  spec.authors       = ["Rafał Rzepecki"]
  spec.email         = ["rafal@conjur.net"]
  spec.summary       = %q{LDAP to Conjur sync}
  spec.description   = %q{Synchronizes users and groups from an LDAP server to a hierarchy of roles in Conjur}
  spec.homepage      = "https://github.com/conjurinc/ldap-sync"
#   spec.license       = "MIT"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_dependency('methadone', '~> 1.3.2')
  spec.add_dependency 'conjur-api', '~> 4.7'
  spec.add_dependency 'treequel', '~> 1.10'

  spec.add_development_dependency "bundler", "~> 1.5"
  spec.add_development_dependency "rake"
  spec.add_development_dependency('rdoc')
  spec.add_development_dependency('aruba')
  spec.add_development_dependency('rake', '~> 0.9.2')
  spec.add_development_dependency 'rspec',  '~> 3.1.0'
  spec.add_development_dependency 'rspec-mocks', '~> 3.1.0'
  spec.add_development_dependency 'rspec-expectations', '~> 3.1.0'
  spec.add_development_dependency 'dotenv', '~> 0.10'

  spec.add_development_dependency 'ladle', '~> 0.2'
end
