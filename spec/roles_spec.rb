require 'spec_helper'

describe Conjur::Ldap::Roles do
  let(:prefix) { 'ldap-test' }
  let(:username){ 'the-user' }
  let(:current_role){ double('current role', roleid: 'current-role-id') }
  let(:roles) do
    Hash.new do |h,id|
      h[id] = double("'#{id}' role", identifier: id)
    end
  end

  let(:groups) do
    Hash.new do |hash, id|
      hash[id] = double("'#{id}' group", role: double("'#{id}' role", members: [])) unless hash.key? id
      hash[id]
    end
  end

  let(:users) do
    Hash.new do |hash, id|
      hash[id] = double "'#{id} user'" unless hash.key? id
      hash[id]
    end
  end

  subject do
    double("Conjur").tap do |x|
      x.extend Conjur::Ldap::Roles
      allow(x).to receive(:create_group) {|id, opts| groups[id]}
      allow(x).to receive(:create_user) {|id, opts| users[id]}
      allow(x).to receive(:username).and_return username
      allow(x).to receive(:current_role).and_return current_role
      allow(x).to receive(:role).with(current_role).and_return current_role
      allow(x).to receive(:group){ |g| double('group ' + g, :exists? => false) }
      allow(x).to receive(:create_variable)
      allow(x).to receive(:user){|u| double('user ' + u, :exists? => false)}
    end
  end

  describe '.sync_to' do
    it "creates the group role" do
      expect(subject).to receive(:create_group).with("#{prefix}/foo")
      subject.sync_to({foo: []}, {prefix: prefix})
    end

    it "creates the user role and grants the group to it" do
      expect(subject).to receive(:create_user).with("#{prefix}/luke")
      expect(groups["#{prefix}/jedi"]).to \
          receive(:grant_to).with("#{prefix}/luke")

      subject.sync_to({jedi: %w(luke)},{prefix: prefix})
    end
  end
end
