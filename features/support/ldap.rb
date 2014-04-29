require 'tempfile'

configfile = Tempfile.new 'ldap-sync-cucumber'
configfile << <<EOF
SSL off
URI ldap://localhost:3897
BASE dc=conjur,dc=net
EOF
configfile.close

ENV['LDAPCONF'] = configfile.path

at_exit do
  configfile.unlink
end
