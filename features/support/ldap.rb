require 'tempfile'
require 'ladle'

module LdapHelpers
  def serve_ldap ldif
    stop_ldap_server
    @ldifile = Tempfile.new ['ldif', '.ldif']
    @ldifile.write ldif
    @ldifile.close

    @ladle = Ladle::Server.new port: 3897,
        ldif: @ldifile.path,
        domain: 'dc=conjur,dc=net',
        tmpdir: '/tmp',
        custom_schemas: %w(org.apache.directory.server.core.schema.bootstrap.NisSchema)
    @ladle.start
  end

  def stop_ldap_server
    @ladle.stop if @ladle
    @ldifile.unlink if @ldifle
    @ladle = @ldifile = nil
  end

  module_function
  def configure_ldap_client
    configfile = Tempfile.new 'ldap-sync-cucumber'
    configfile << """
      SSL off
      URI ldap://localhost:3897
      BASE dc=conjur,dc=net
    """
    configfile.close

    ENV['LDAPCONF'] = configfile.path

    at_exit do
      configfile.unlink
    end
  end
end

LdapHelpers.configure_ldap_client

World LdapHelpers
After do
  stop_ldap_server
end
