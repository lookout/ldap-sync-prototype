require 'spec_helper'

describe Conjur::Ldap::Adapter::ActiveDirectory do
  # Monkey patch helpers onto AD classes
  before do
    class ::Conjur::Ldap::Adapter
      class Model
        def user_named name
          users.find{|u| u.name == name}
        end
        def group_named name
          groups.find{|g| g.name == name}
        end
      end
      class Group
        def has_member_named? name
          !!member_named(name)
        end
        def member_named name
          members.find{|m| m.name == name}
        end
      end
      class User
        def group_named name
          groups.find{|g| g.name == name}
        end
        def has_group_named? name
          !!group_named(name)
        end
      end
    end
  end

  shared_context 'mock AD' do
    let(:base_dn){'DC=joshco,DC=com'}
    let(:directory){ double('directory', base_dn: base_dn) }
    let(:user_search_results){ [] } # Array of hashes
    let(:group_search_results){ [] } # Array of hashes
    let(:users_filter){ '(|(objectClass=user)(objectClass=posixAccount))' }
    let(:groups_filter){ '(|(objectClass=group)(objectClass=posixGroup))' }
    before do
      allow(directory).to receive(:search)
                               .with(base_dn, :subtree, users_filter)
                               .and_return user_search_results
      allow(directory).to receive(:search)
                               .with(base_dn, :subtree, groups_filter)
                               .and_return group_search_results
    end
  end


  shared_context 'simple directory structure' do
    let(:admin_dn){ 'CN=Administrator,CN=Users,DC=joshco,DC=com' }
    let(:alice_dn){ 'CN=Alice,CN=Users,DC=joshco,DC=com' }
    let(:domain_admins_dn){ 'CN=Domain Admins,CN=Users,DC=joshco,DC=com' }
    let(:dns_admins_dn){ 'CN=DnsAdmins,CN=Users,DC=joshco,DC=com' }

    let(:group_search_results) do
      [
          {
              'distinguishedName' => domain_admins_dn,
              'cn' => 'Domain Admins',
              'member' => [admin_dn]
          },
          {
            'distinguishedName' => dns_admins_dn,
            'member' => [admin_dn, alice_dn],
            'cn' => 'DnsAdmins'
          }
      ]
    end
    let(:user_search_results) do
        [
            {
              'distinguishedName' => alice_dn,
              'cn' => 'Alice',
              'uidNumber' => '1234',
              'memberOf' => [dns_admins_dn]
            },
            {
              'distinguishedName' => admin_dn,
              'cn' => 'Administrator',
              'uidNumber' => '1111',
              'memberOf' => [dns_admins_dn, domain_admins_dn]
            }
      ]
    end
  end

  describe 'an adapter instance with mock AD and simple directory structure' do
    include_context 'mock AD'
    include_context 'simple directory structure'
    let(:adapter){ Conjur::Ldap::Adapter.for mode: :active_directory, directory: directory }


    describe '#load_model' do
      subject{ adapter.load_model }

      it 'returns a Conjur::Ldap::Adapter::Model instance' do
        expect(subject).to be_kind_of Conjur::Ldap::Adapter::Model
      end

      it 'returns a model with two groups' do
        expect(subject.groups.length).to be(2)
      end

      it 'returns a model with two users' do
        expect(subject.users.length).to be(2)
      end

      it 'returns a DnsAdmins group with Alice and Administrator as members' do
        expect(found = subject.group_named('DnsAdmins')).to_not be_nil
        expect(found).to have_member_named 'Alice'
        expect(found).to have_member_named 'Alice'
        expect(found.members.length).to be(2)
      end

      it 'returns a Domain_Admins group with Administrator as a member' do
        expect(found = subject.group_named('Domain_Admins')).to_not be_nil
        expect(found).to have_member_named 'Administrator'
        expect(found.members.length).to be 1
      end

      it 'returns a user Alice who is a member of DnsAdmins' do
        expect(found = subject.user_named('Alice')).to_not be_nil
        expect(found).to be_in_group_named 'DnsAdmins'
        expect(found.groups.length).to be(1)
      end

      it 'returns a user Administrator who is a member of DnsAdmins and Domain_Admins' do
        expect(found = subject.user_named('Administrator')).to_not be_nil
        expect(found).to be_in_group_named 'DnsAdmins'
        expect(found).to be_in_group_named 'Domain_Admins'
      end

    end
  end


end