require 'spec_helper'

describe Conjur::Ldap::Roles do
  subject{ double('api').extend(described_class) }
  let(:user){ double('user') }
  let(:group){ double('group') }
  let(:roleid){ 'owner-role' }
  let(:role){ double('owner-role', roleid: roleid) }
  let(:base_opts) do
    {
        save_api_keys: false,
        ignore_ldap_ids: true,
        marker_tag: 'ImportedFrom=LDAP',
        owner: roleid
    }
  end

  let(:annotations){ double('annotations') }
  let(:resource){ double('resource', annotations: annotations) }
  let(:conjur_user){ double('conjur user', :exists? => false, resource: resource) }
  let(:conjur_group){ double('conjur group', :exists? => false, resource: resource) }
  let(:group){ double('group', name: 'users', dn: nil, gid: 1234, members: []) }
  let(:user){ double('user',name: 'alice', dn: nil, uid: 123, groups: []) }
  let(:users){ [user] }
  let(:groups){ [group] }
  let(:model) do
    double('model', users: users, groups: groups)
  end


  before do
    Conjur::Ldap::Reporting.reporter.io = nil
    group.members << user
    user.groups << group
    allow(subject).to receive(:find_role).with(roleid).and_return role
    allow(subject).to receive(:user).with(user.name).and_return(conjur_user)
    allow(subject).to receive(:group).with(group.name).and_return(conjur_group)
    allow(subject).to receive(:create_user).with(user.name, ownerid: roleid).and_return(conjur_user)
    allow(subject).to receive(:create_group).with(group.name, ownerid: roleid).and_return(conjur_group)
    allow(annotations).to receive(:[]=).with 'ImportedFrom', 'LDAP'
  end

  shared_context 'no updates' do
    before do
      allow(subject).to receive(:update_group_memberships)
    end

  end


  describe 'annotations' do
    include_context 'no updates'

    it 'adds them' do
      expect(annotations).to receive(:[]=).with('Foo','BAR').at_least(:once)
      subject.sync_to model, base_opts.merge(marker_tag: 'Foo=BAR')
    end
  end
end