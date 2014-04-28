Then(/^role "(.*?)" should exist$/) do |arg1|
  @conjur.role(mangle_name arg1).should exist
end
