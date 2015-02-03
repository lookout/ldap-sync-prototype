Then(/^(?:the )?role "(.*?)" should exist$/) do |role|
  @last_role = @conjur.role(mangle_name role)
  @last_role.should exist
end

Then(/^it should (not )?be a member of "(.*?)"$/) do |neg, role|
  role = @conjur.role(mangle_name role)
  @last_role.member_of?(role).should == neg.nil?
end


When %r{^I( successfully)? sync(?: with options "(.*)")?$} do |successfully, options|
  puts "export CONJUR_LDAP_SYNC_PREFIX='#{conjur_prefix}'"
  set_env 'CONJUR_LDAP_SYNC_PREFIX', conjur_prefix
  command = mangle_name "conjur-ldap-sync #{options}"
  puts "run: #{command}"
  run_simple unescape(command), !!successfully
end

Then %r{^it should (not )?be owned by "(.*?)"$} do |neg, owner|
  owner = "conjur:#{mangle_name(owner)}"
  kind = @last_role.kind
  ownerid = conjur.send(kind, @last_role.identifier).ownerid
  if neg
    expect(ownerid).to_not eq(owner)
  else
    expect(ownerid).to eq(owner)
  end
end

Then %r{the variable "(.*?)" should (not )?exist} do |name, neg|
  id = mangle_name(name)
  var = conjur.variable(id)
  if neg
    expect(var).to_not exist
  else
    expect(var).to exist
    expect(var.version_count).to be > 0
  end
  @last_variable_id = id
end

And %r{role "(.*?)" can execute the variable} do |role|
  role = conjur.role(mangle_name role)
  expect(role.permitted?("conjur:variable:#{@last_variable_id}", 'execute')).to be_truthy
end

Given %r{^a role named "(.*?)"$} do |rolename|
  roles_by_name[rolename] = find_or_create_role(rolename)
end

Then %r{^a user named "(.*?)" exists and has the uid for "(.*?)"} do |username, uidfor|
  uid = uids[uidfor]
  user = conjur.user(mangle_name username)
  expect(user).to exist
  expect(user.attributes['uidnumber'].to_s).to eq(uid.to_s)
end

Then %r{^a group named "(.*?)" exists and has the gid for "(.*?)"$} do |groupname, gidfor|
  gid = gids[gidfor]
  group = conjur.group mangle_name(groupname)
  expect(group).to exist
  expect(group.attributes['gidnumber'].to_s).to eq(gid.to_s)
end