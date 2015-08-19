require 'spec_helper'

describe Conjur::Ldap::Roles do
  let(:api){ double('api') }
  subject{ described_class.new(api, options) }

  let(:user){ double('user') }
  let(:group){ double('group') }
  let(:roleid){ 'owner-role' }
  let(:role){ double('owner-role', roleid: roleid) }
  let(:base_opts) do
    {
        save_api_keys: false,
        ignore_ldap_ids: true,
        owner: roleid
    }
  end
  let(:options){ base_opts }

  let(:annotations){ double('annotations') }
  let(:resource){ double('resource', annotations: annotations) }
  let(:empty_role){ double('empty role', members: [], memberships: []) }
  let(:conjur_user){ double('conjur user', :exists? => false, resource: resource,
                            role: empty_role, name: user.name) }
  let(:conjur_group){ double('conjur group', :exists? => false, resource: resource,
                             role: empty_role, name: group.name) }
  let(:group){ double('group', name: 'users', dn: 'cn=users,dc=conjur,dc=net', gid: 1234, members: []) }
  let(:user){ double('user',name: 'alice', dn: 'cn=alice,dc=conjur,dc=net', uid: 123, groups: []) }
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
    allow(api).to receive(:user).with(user.name).and_return(conjur_user)
    allow(api).to receive(:group).with(group.name).and_return(conjur_group)
    allow(api).to receive(:create_user).with(user.name, ownerid: roleid).and_return(conjur_user)
    allow(api).to receive(:create_group).with(group.name, ownerid: roleid).and_return(conjur_group)
  end

  shared_context 'no updates' do
    before do
      allow(subject).to receive(:remove_user_from_groups)
      allow(subject).to receive(:remove_members_from_group)
    end
  end

  describe 'annotations' do
    include_context 'no updates'

    let(:options){ base_opts.merge(marker_tag: 'blah') }

    it 'adds them' do
      expect(annotations).to receive(:merge!).with(
                                 'ldap-sync/source' => 'blah',
                                 'ldap-sync/upstream-dn' => group.dn
                             )
      expect(annotations).to receive(:merge!).with(
                                 'ldap-sync/source' => 'blah',
                                 'ldap-sync/upstream-dn' => user.dn
                             )

      subject.sync_to model
    end

    context 'with no :marker_tag option' do
      let(:current_roleid){ 'current-role-id' }
      let(:current_role){ double('current role', roleid: current_roleid) }

      let(:options){ base_opts }

      before do
        allow(api).to receive(:current_role).and_return current_role
      end

      it 'sets the ldap-sync/source annotation to the current role id' do
        [user, group].each do |role|
          expect(annotations).to receive(:merge!).with(
                                     'ldap-sync/source' => current_roleid,
                                     'ldap-sync/upstream-dn' => role.dn
                                 )
        end
        subject.sync_to model
      end
    end
  end
end