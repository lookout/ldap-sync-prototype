Given(/^(?:I initially have )?(?:an )?LDAP database with:$/) do |string|
  serve_ldap insert_uids(string)
end

Then(/^the LDAP database changes to$/) do |string|
  serve_ldap insert_uids(string)
end
