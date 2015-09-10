require 'simplecov'

# We need to do a bit more work to set up coverage when we're in a conjur-ldap-sync
# process started by a feature.

# We need a unique command name for each run of the command, or the coverage
# results will clober each other.
unless command_name = ENV['LDAP_SYNC_TEST_NAME']
  puts "WARNING: You are running conjur-ldap-sync in a test environment, but you haven't provided
 LDAP_SYNC_TEST_NAME: if you run the command multiple times, your results will clobber each other!"
  command_name = 'conjur-ldap-sync'
end

SimpleCov.command_name command_name
# SimpleCov can't figure out where we are in this situation
SimpleCov.root File.join File.dirname(__FILE__), '../../'
SimpleCov.coverage_dir 'coverage'
SimpleCov.start
puts 'SimpleCov started!'