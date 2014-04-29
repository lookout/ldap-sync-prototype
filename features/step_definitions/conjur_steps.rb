Then(/^role "(.*?)" should exist$/) do |role|
  @last_role = @conjur.role(mangle_name role)
  @last_role.should exist
end

Then(/^it should be a member of "(.*?)"$/) do |role|
  role = @conjur.role(mangle_name role)
  @last_role.member_of?(role).should be_true
end
