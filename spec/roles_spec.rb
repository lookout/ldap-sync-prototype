require 'spec_helper'

describe Conjur::Ldap::Roles do
  let(:prefix) { 'ldap-test' }
  let(:roles) do
    Hash.new do |hash, id|
      hash[id] = double "'#{id}' role" unless hash.key? id
      hash[id]
    end
  end

  subject do
    double("Conjur").tap do |x|
      x.extend Conjur::Ldap::Roles
      x.stub prefix: prefix
      x.stub :create_role, &roles.method(:[])
    end
  end

  describe '.sync_to' do
    it "creates the group role" do
      expect(subject).to receive(:create_role).with("ldap-group:#{prefix}/foo")
      subject.sync_to foo: []
    end

    it "creates the user role and grants the group to it" do
      expect(subject).to receive(:create_role).with("ldap-user:#{prefix}/luke")
      expect(roles["ldap-group:#{prefix}/jedi"]).to \
          receive(:grant_to).with("ldap-user:#{prefix}/luke")

      subject.sync_to jedi: %w(luke)
    end
  end
end
