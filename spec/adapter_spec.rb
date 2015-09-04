require 'spec_helper'

class DummyAdapter < Conjur::Ldap::Adapter
  register_adapter_class :dummy
  def initialize opts
    super opts.reverse_merge(directory: true)
  end
end

describe Conjur::Ldap::Adapter do

  describe 'class methods' do
    describe '+register_adapter_class' do

      subject{ described_class }

      let!(:klass) do
        Class.new(subject) do
          register_adapter_class :test
        end

      end

      it '[:test] should return the class' do
        expect(subject[:test]).to eq(klass)
      end

      it 'for(:mode => :test, :option => 2) should return a new instance of klass' do
        # pass directory: true to prevent it from attempting to connect to an actual ldap.
        instance = subject.for(mode: :test, option: 2, directory: true)
        expect(instance.options[:option]).to be(2)
      end
    end
  end

  describe 'instance methods' do

    let(:directory){ double('directory') }
    let(:base_options){{mode: :dummy, directory:directory}}
    let(:options){ {} }
    subject{ described_class.for(base_options.merge(options))}


    shared_examples_for 'an object class filter method' do
      context 'when no options are given' do
        it 'makes an or filter with #default_x_object_classes' do
          allow(subject).to receive(:"default_#{kind}_object_classes").and_return %w(foo bar)
          expect(subject.send(:"#{kind}s_filter")).to eq('(|(objectClass=foo)(objectClass=bar))')
        end
      end
      context 'when options are present' do
        let(:options){{:"#{kind}_object_classes" => %w(xyz abc)}}
        it 'makes an or filter with the options[:x_object_classes]' do
          expect(subject.send(:"#{kind}s_filter")).to eq('(|(objectClass=xyz)(objectClass=abc))')
        end
      end
    end

    describe '#users_filter' do
      let(:kind){:user}
      it_should_behave_like 'an object class filter method'
    end

    describe '#groups_filter' do
      let(:kind){:group}
      it_should_behave_like 'an object class filter method'
    end

    context 'with --user-filter and --group-filter' do
      let(:group_filter){ '(&(ou=ConjurGroups)(objectClass=group))' }
      let(:user_filter){'(&(ou=ConjurGroups)(objectClass=group))' }
      let(:options){ {group_filter: group_filter, user_filter: user_filter} }

      describe '#users_filter' do
        it('returns the user_filter option'){
          expect(subject.users_filter).to eq(user_filter) }
      end

      describe '#groups_filter' do
        it('returns the user_filter option'){
          expect(subject.users_filter).to eq(user_filter) }
      end
    end

    shared_examples_for 'a find method' do
      let(:base_dn){ 'dc=conjur,dc=net' }
      let(:directory){ double('directory', base_dn: base_dn) }
      let(:result){ double('search result') }
      let(:filter){ "(objectClass=#{kind})"}

      before do
        allow(subject).to receive(:"#{kind}s_filter").and_return filter
        allow(directory).to receive(:search).with(base_dn, :subtree, filter).and_return result
      end

      it 'calls directory.search with the correct objectClass filter' do
        expect(subject.send(:"find_#{kind}s")).to be(result)
      end
    end

    describe '#find_users' do
      let(:kind){:user}
      it_should_behave_like 'a find method'
    end

    describe '#find_groups' do
      let(:kind){ :group }
      it_should_behave_like 'a find method'
    end
  end


end