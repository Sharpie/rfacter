#! /usr/bin/env ruby

require 'spec_helper'
require 'rfacter/util/collection'

describe RFacter::Util::Collection do
  include_context 'mock rfacter configuration'

  let(:node) { instance_double('RFacter::Node') }
  let(:fact) { instance_double('RFacter::Util::Fact') }
  subject { described_class.new(node) }

  describe "when adding facts" do
    it "should create a new fact if no fact with the same name already exists" do
      subject.add(:myname)
      expect(subject.fact(:myname).name).to eq(:myname)
    end

    it "should accept options" do
      subject.add(:myname, :timeout => 1) { }
    end

    it "passes resolution specific options to the fact" do
      allow(RFacter::Util::Fact).to receive(:new).with(:myname, {:timeout => 'myval'}).and_return(fact)

      expect(fact).to receive(:add).with({:timeout => 'myval'})

      subject.add(:myname, :timeout => "myval") {}
    end

    describe "and a block is provided" do
      it "should use the block to add a resolution to the fact" do
        allow(RFacter::Util::Fact).to receive(:new).and_return(fact)

        expect(fact).to receive(:add)

        subject.add(:myname) {}
      end

      it "should discard resolutions that throw an exception when added" do
        expect(logger).to receive(:log_exception).with(
          RuntimeError,
         /Unable to add resolve .* kaboom!/)
        expect(logger).to receive(:debug).with(/is still nil/)

        expect {
          subject.add('yay') do
            raise "kaboom!"
          end
        }.to_not raise_error
        expect(subject.value('yay')).to be_nil
      end
    end
  end

  describe "when only defining facts" do
    it "creates a new fact if no such fact exists" do
      allow(RFacter::Util::Fact).to receive(:new).with(:newfact, {}).and_return(fact)
      expect(subject.define_fact(:newfact)).to equal fact
    end

    it "returns an existing fact if the fact has already been defined" do
      fact = subject.define_fact(:newfact)
      expect(subject.define_fact(:newfact)).to equal fact
    end

    it "logs a warning if the fact could not be defined" do
      expect(logger).to receive(:log_exception).with(
        RuntimeError,
        "Unable to add fact newfact: kaboom!")

      subject.define_fact(:newfact) do
        raise "kaboom!"
      end
    end
  end

  describe "when retrieving facts" do
    before do
      @fact = subject.add("YayNess")
    end

    it "should return the fact instance specified by the name" do
      expect(subject.fact("YayNess")).to equal(@fact)
    end

    it "should be case-insensitive" do
      expect(subject.fact("yayness")).to equal(@fact)
    end

    it "should treat strings and symbols equivalently" do
      expect(subject.fact(:yayness)).to equal(@fact)
    end
  end

  describe "when returning a fact's value" do
    before do
      @fact = subject.add("YayNess", :value => "result")
    end

    it "should return the result of calling :value on the fact" do
      expect(subject.value("YayNess")).to eq("result")
    end

    it "should be case-insensitive" do
      expect(subject.value("yayness")).to eq("result")
    end

    it "should treat strings and symbols equivalently" do
      expect(subject.value(:yayness)).to eq("result")
    end
  end

  it "should return the fact's value when the array index method is used" do
    subject.add("myfact", :value => "foo")

    expect(subject["myfact"]).to eq("foo")
  end

  it "should have a method for flushing all facts" do
    fact = subject.add("YayNess")

    expect(fact).to receive(:flush)

    subject.flush
  end

  it "should have a method that returns all fact names" do
    subject.add(:one)
    subject.add(:two)

    expect(subject.list.sort { |a,b| a.to_s <=> b.to_s }).to include(:one, :two)
  end

  describe "when returning a hash of values" do
    it "should return a hash of fact names and values with the fact names as strings" do
      subject.add(:one, :value => "me")

      expect(subject.to_hash).to eq({"one" => "me"})
    end

    it "should not include facts that did not return a value" do
      subject.add(:two, :value => nil)
      expect(logger).to receive(:debug).with(/still nil/)

      expect(subject.to_hash).to_not include(:two)
    end
  end

  describe "when iterating over facts" do
    before do
      subject.add(:one, :value => "ONE")
      subject.add(:two, :value => "TWO")

      # Stub out fact loading
      allow(subject).to receive(:load_all)
    end

    it "should yield each fact name and the fact value" do
      facts = {}
      subject.each do |fact, value|
        facts[fact] = value
      end
      expect(facts).to eq({"one" => "ONE", "two" => "TWO"})
    end

    it "should convert the fact name to a string" do
      facts = {}
      subject.each do |fact, value|
        expect(fact).to be_instance_of(String)
      end
    end

    it "should only yield facts that have values" do
      subject.add(:nil_fact, :value => nil)
      expect(logger).to receive(:debug).with(/still nil/)
      facts = {}

      subject.each do |fact, value|
        facts[fact] = value
      end

      expect(facts).to_not be_include("nil_fact")
    end
  end

  describe "when no facts are loaded" do
    it "should warn when no facts were loaded" do
      # Stub out fact loading
      allow(subject).to receive(:load_all)
      expect(logger).to receive(:warnonce).with(/No facts loaded/)

      subject.fact("one")
    end
  end
end
