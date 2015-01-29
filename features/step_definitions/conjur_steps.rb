Then(/^(?:the )?role "(.*?)" should exist$/) do |role|
  @last_role = @conjur.role(mangle_name role)
  @last_role.should exist
end

Then(/^it should (not )?be a member of "(.*?)"$/) do |neg, role|
  role = @conjur.role(mangle_name role)
  @last_role.member_of?(role).should == neg.nil?
end


When %r{^I( successfully)? sync(?: with options "(.*)")?$} do |successfully, options|
  options ||= ''
  options << ' --prefix <prefix>' unless options.index '--prefix'
  command = mangle_name "conjur-ldap-sync #{options}"
  # puts "RUNNING #{command}"
  step "I#{successfully ||' '} run `#{command}`"
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