#! /usr/bin/env ruby

require 'spec_helper'
require 'rfacter/util/fact'

describe RFacter::Util::Fact do
  include_context 'mock rfacter configuration'

  subject(:fact) { RFacter::Util::Fact.new("yay") }

  let(:resolution) { RFacter::Util::Resolution.new("yay", fact) }

  it "requires a name" do
    expect { RFacter::Util::Fact.new }.to raise_error(ArgumentError)
  end

  it "downcases and converts the name to a symbol" do
    expect(RFacter::Util::Fact.new("YayNess").name).to eq :yayness
  end

  describe "when adding resolution mechanisms using #add" do
    it "delegates to #define_resolution with an anonymous resolution" do
      expect(subject).to receive(:define_resolution).with(nil, {})
      subject.add
    end
  end

  describe "looking up resolutions by name" do
    subject(:fact) { described_class.new('yay') }

    it "returns nil if no such resolution exists" do
      expect(fact.resolution('nope')).to be_nil
    end

    it "never returns anonymous resolutions" do
      fact.add() { setcode { 'anonymous' } }

      expect(fact.resolution(nil)).to be_nil
    end
  end

  describe "adding resolution mechanisms by name" do

    let(:res) do
      double 'resolution',
        :name => 'named',
        :set_options => nil,
        :resolution_type => :simple
    end

    it "creates a new resolution if no such resolution exists" do
      expect(RFacter::Util::Resolution).to receive(:new).once.with('named', fact).and_return(res)

      fact.define_resolution('named')

      expect(fact.resolution('named')).to eq res
    end

    it "creates a simple resolution when the type is nil" do
      fact.define_resolution('named')
      expect(fact.resolution('named')).to be_a_kind_of RFacter::Util::Resolution
    end

    it "creates a simple resolution when the type is :simple" do
      fact.define_resolution('named', :type => :simple)
      expect(fact.resolution('named')).to be_a_kind_of RFacter::Util::Resolution
    end

    it "creates an aggregate resolution when the type is :aggregate" do
      fact.define_resolution('named', :type => :aggregate)
      expect(fact.resolution('named')).to be_a_kind_of RFacter::Core::Aggregate
    end

    it "raises an error if there is an existing resolution with a different type" do
      pending "We need to stop rescuing all errors when instantiating resolutions"
      fact.define_resolution('named')
      expect {
        fact.define_resolution('named', :type => :aggregate)
      }.to raise_error(ArgumentError, /Cannot return resolution.*already defined as simple/)
    end

    it "returns existing resolutions by name" do
      expect(RFacter::Util::Resolution).to receive(:new).once.with('named', fact).and_return(res)

      fact.define_resolution('named')
      fact.define_resolution('named')

      expect(fact.resolution('named')).to eq res
    end
  end

  describe "when returning a value" do
    it "returns nil if there are no resolutions" do
      expect(logger).to receive(:debug).with(/No resolves for/)

      expect(RFacter::Util::Fact.new("yay").value).to be_nil
    end

    it "prefers the highest weight resolution" do
      fact.add { has_weight 1; setcode { "1" } }
      fact.add { has_weight 2; setcode { "2" } }
      fact.add { has_weight 0; setcode { "0" } }
      expect(fact.value).to eq "2"
    end

    it "returns the first value returned by a resolution" do
      fact.add { has_weight 1; setcode { "1" } }
      fact.add { has_weight 2; setcode { nil } }
      fact.add { has_weight 0; setcode { "0" } }
      expect(fact.value).to eq "1"
    end

    it "skips unsuitable resolutions" do
      fact.add { has_weight 1; setcode { "1" } }
      fact.add do
        def suitable?; false; end
        has_weight 2
        setcode { 2 }
      end

      expect(fact.value).to eq "1"
    end
  end

  describe '#flush' do
    subject do
      RFacter::Util::Fact.new(:foo)
    end

    it "invokes #flush on all resolutions" do
      simple = subject.add(:type => :simple)
      expect(simple).to receive(:flush)

      aggregate = subject.add(:type => :aggregate)
      expect(aggregate).to receive(:flush)

      subject.flush
    end
  end
end
