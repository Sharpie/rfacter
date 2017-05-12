require 'forwardable'

require 'spec_helper'
require 'rfacter/core/resolvable'
require 'rfacter/util/fact'

describe RFacter::Core::Resolvable do
  include_context 'mock rfacter configuration'

  class ResolvableClass
    extend Forwardable
    instance_delegate([:logger] => :@config)

    def initialize(name, config: RFacter::Config.config)
      @name = name
      @fact = RFacter::Util::Fact.new("stub fact")
      @config = config
    end
    attr_accessor :name, :resolve_value
    attr_reader :fact
    include RFacter::Core::Resolvable
  end

  subject { ResolvableClass.new('resolvable') }

  it "has a default timeout of 0 seconds" do
    expect(subject.limit).to eq 0
  end

  it "can specify a custom timeout" do
    subject.timeout = 10
    expect(subject.limit).to eq 10
  end

  describe "generating a value" do
    it "returns the results of #resolve_value" do
      subject.resolve_value = 'stuff'
      expect(subject.value).to eq 'stuff'
    end

    it "normalizes the resolved value" do
      allow(RFacter::Util::Normalization).to receive(:normalize).and_return('stuff')
      subject.resolve_value = 'stuff'
      expect(subject.value).to eq('stuff')
    end

    it "logs a warning if an exception was raised" do
      expect(subject).to receive(:resolve_value).and_raise(RuntimeError, "kaboom!")
      expect(logger).to receive(:log_exception).with(
        RuntimeError,
        /Could not retrieve .*: kaboom!/)
      expect(subject.value).to eq nil
    end

    it 'does not collect measurements when timing is disabled' do
      allow(config).to receive(:timing).and_return(false)
      expect(Process).to receive(:clock_gettime).never

      subject.value
    end

    it 'logs elapsed time when timining is enabled' do
      allow(config).to receive(:timing).and_return(true)
      expect(logger).to receive(:info)

      subject.value
    end
  end

  describe "timing out" do
    it "uses #limit instead of #timeout to determine the timeout period" do
      expect(subject).to receive(:timeout).never
      allow(subject).to receive(:limit).and_return(25)

      expect(Timeout).to receive(:timeout).with(25)
      subject.value
    end

    it "returns nil if the timeout was reached" do
      expect(logger).to receive(:log_exception).with(
        Timeout::Error,
        /Timed out after 0\.1 seconds while resolving/)
      allow(Timeout).to receive(:timeout).and_raise(Timeout::Error)

      subject.timeout = 0.1

      expect(subject.value).to be_nil
    end
  end

  describe 'callbacks when flushing facts' do
    class FlushFakeError < StandardError; end

    context '#on_flush' do
      it 'accepts a block with on_flush' do
        subject.on_flush() { raise NotImplementedError }
      end
    end

    context '#flush' do
      it 'calls the block passed to on_flush' do
        subject.on_flush() { raise FlushFakeError }
        expect { subject.flush }.to raise_error FlushFakeError
      end
    end
  end
end
