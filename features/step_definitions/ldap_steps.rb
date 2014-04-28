require 'tempfile'
require 'ladle'

Given(/^LDAP database with:$/) do |string|
  @ldifile = Tempfile.new ['ldif', '.ldif']
  @ldifile.write string
  @ldifile.close

  @ladle = Ladle::Server.new port: 3897,
      ldif: @ldifile.path,
      domain: 'dc=conjur,dc=net',
      tmpdir: '/tmp',
      custom_schemas: %w(org.apache.directory.server.core.schema.bootstrap.NisSchema)
  @ladle.start
end

After do
  @ladle.stop if @ladle
  @ldifile.unlink if @ldifle
  @ladle = @ldifile = nil
end
