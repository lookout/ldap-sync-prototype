def def_matcher *args, &block
  RSpec::Matchers.define *args,&block
end

def_matcher :have_member_named do |expected_name|
  match do |group|
    group.has_member_named? expected_name
  end
end

def_matcher :be_in_group_named do |expected_name|
  match do |user|
    user.has_group_named? expected_name
  end
end


def_matcher :have_length do |len|
  match do |ary|
    ary.length == len
  end
end
