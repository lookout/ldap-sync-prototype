require 'spec_helper'

describe Conjur::Ldap::Reporting do
  subject { Object.new.extend(described_class) }

  it 'should respond to :report' do
    expect(subject).to respond_to(:report)
  end

  it 'should have a reporter' do
    expect(subject.reporter).to be_kind_of(Conjur::Ldap::Reporting::Reporter)
  end

  describe '#report' do

    def self.it_should_have_report attrs, &before
      it "should have report #{attrs}" do
        instance_eval(&before)
        subject.reporter.reports.map(&:as_json).each do |report|
          attrs.each do |key, val|
            expect(report[key]).to eq(val)
          end
        end
      end
    end

    describe 'after calling report(:some_tag, "hi", foo: "bar")' do
      context 'without a block' do
        it_should_have_report tag: :some_tag, message: 'hi', foo: 'bar', result: :success do
          subject.report :some_tag, 'hi', foo: 'bar'
        end
      end
      context 'with a successful block' do
        it_should_have_report tag: :some_tag, message: 'hi', foo: 'bar', result: :success do
          called = false
          subject.report :some_tag, 'hi', foo: 'bar' do
            called = true
          end
          expect(called).to be_truthy
        end
      end
      context 'with a block that raises' do
        it_should_have_report tag: :some_tag, message: 'hi', foo: 'bar', result: :failure, error: 'BOOM' do
          expect do
            subject.report :some_tag, 'hi', foo: 'bar' do
              raise 'BOOM'
            end
          end.to raise_exception
        end
      end
    end
    
    describe 'after three calls to report' do
      before do
        subject.report :first, 'The first call'
        subject.report(:second, 'The second call', some_key: 'blah'){}
        begin
          subject.report(:third, 'This fails'){ raise 'BOOM' }
        rescue
          # empty
        end
      end
      
      describe 'reporter.dump' do
        let(:dumped) do 
          StringIO.new.tap do |io|
            subject.reporter.dump io
          end.string
        end
        
        it 'is valid JSON' do
          expect{JSON.parse(dumped)}.to_not raise_exception
        end
        
        describe 'the parsed JSON' do
          let(:json){ JSON.parse dumped }
          it 'should be a hash with keys "actions", "succeeded", and "failed"' do
            # note that we're taking advantage of the fact that JSON hashes and ruby hashes are ordered.  We 
            # want this order in particular for readability.
            expect(json).to be_kind_of Hash
            expect(json.keys).to eq(%w(actions succeeded failed))
          end
          
          describe 'json["actions"]' do
            let(:actions){ json['actions'] }
            it 'should be an array with three elements' do
              expect(actions).to be_kind_of(Array)
              expect(actions.length).to eq(3)
            end
            it 'should have tags :first, :second, and :third' do
              expect(actions.map{|a| a['tag']}).to eq(%w(first second third))
            end
            it 'should preserve extras' do
              expect(actions[1]['some_key']).to eq('blah')
            end
          end
          
          describe 'json["failed"]' do
            let(:failed){ json['failed'] }
            it 'should be an array with one element' do
              expect(failed).to be_kind_of(Array)
              expect(failed.length).to eq(1)
            end
            it 'should contain the failed report' do
              expect(failed[0]['message']).to eq('This fails')
            end
          end
          
          describe 'json["succeeded"]' do 
            let(:succeeded){ json['succeeded'] }
            it 'should be an array with two elements' do
              expect(succeeded).to be_kind_of(Array)
              expect(succeeded.length).to eq(2)
            end
            it 'should contain the reports that succeeded' do
              expect(succeeded.map{|r| r['tag']}).to eq(%w(first second))
            end
          end
        end
      end
    end


  end

end