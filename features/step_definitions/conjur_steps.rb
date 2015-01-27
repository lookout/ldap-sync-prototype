Then(/^(?:the )?role "(.*?)" should exist$/) do |role|
  @last_role = @conjur.role(mangle_name role)
  @last_role.should exist
end

Then(/^it should (not )?be a member of "(.*?)"$/) do |neg, role|
  role = @conjur.role(mangle_name role)
  @last_role.member_of?(role).should == neg.nil?
end

When %r{^I( successfully)? sync} do |successfully|
  command = mangle_name 'conjur-ldap-sync --prefix <prefix>'
  step "I#{successfully ||' '} run `#{command}`"
end
