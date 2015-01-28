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

Given %r{^a role named "(.*?)"$} do |rolename|
  roles_by_name[rolename] = find_or_create_role(rolename)
end