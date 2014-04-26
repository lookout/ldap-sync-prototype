Then(/^role "(.*?)" should exist$/) do |arg1|
  @conjur.role(arg1).should_exist
end
