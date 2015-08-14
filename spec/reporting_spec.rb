require 'spec_helper'

describe Conjur::Ldap::Reporting do
  subject { Object.new.extend(described_class) }

  before do
    ENV['CONJUR_LDAP_SYNC_LOG_LEVEL'] = 'FATAL'
    subject.reporter.instance_eval do
      @reports = []
    end
  end

  it 'should respond to :report' do
    expect(subject).to respond_to(:report)
  end

  it 'should have a reporter' do
    expect(subject.reporter).to be_kind_of(Conjur::Ldap::Reporting::Reporter)
  end

  describe '#report' do
    let(:output) { StringIO.new }

    let(:output_lines) { output.string.split(/\n/) }
    before do
      subject.reporter.io = output
    end


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
        it_should_have_report tag: :some_tag, foo: 'bar', result: :success do
          subject.report :some_tag, foo: 'bar'
        end
      end
      context 'with a successful block' do
        it_should_have_report tag: :some_tag, foo: 'bar', result: :success do
          called = false
          subject.report :some_tag, foo: 'bar' do
            called = true
          end
          expect(called).to be_truthy
        end
      end
      context 'with a block that raises' do
        it_should_have_report tag: :some_tag, foo: 'bar', result: :failure, error: 'BOOM' do
          expect do
            subject.report :some_tag, foo: 'bar' do
              raise 'BOOM'
            end
          end.to_not raise_exception
        end
      end
    end

    context 'with json output_format' do


      before do
        subject.reporter.output_format = :json
      end


      describe 'after three calls to report' do
        before do
          subject.report :first
          subject.report(:second, some_key: 'blah') {}
          begin
            subject.report(:third) { raise 'BOOM' }
          rescue
            # empty
          end
        end

        describe 'reporter output' do
          it 'is valid newline separated JSON' do
            expect { output_lines.map { |line| JSON.parse(line) } }.to_not raise_exception
          end

          describe 'the parsed JSON' do
            let(:json) { output_lines.map { |line| JSON.parse(line) } }

            it 'should be an array with three elements' do
              expect(json.length).to be(3)
            end
            it 'should have tags :first, :second, and :third' do
              expect(json.map { |a| a['tag'] }).to eq(%w(first second third))
            end
            it 'should preserve extras' do
              expect(json[1]['some_key']).to eq('blah')
            end
          end
        end
      end
    end

    context 'with text output_format' do
      before do
        subject.reporter.output_format = :text
      end

      describe 'after three calls to report' do
        before do
          subject.report :first
          subject.report :second, some_key: 'blah'
          begin
            subject.report(:third) { raise 'BOOM' }
          rescue
            # empty
          end
        end

        describe 'the output' do

          it 'has three elements' do
            expect(output_lines).to have_length(3)
          end

          it 'has the right contents' do
            expect(output_lines).to eq([
                                           'first: result=success',
                                           'second: result=success, some_key=blah',
                                           'third: error=BOOM, result=failure'
                                       ])
          end
        end
      end
    end


  end

end