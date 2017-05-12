#! /usr/bin/env ruby

require 'spec_helper'
require 'rfacter/util/loader'

describe RFacter::Util::Loader do
  include_context 'mock rfacter configuration'

  let(:collection) { instance_double('RFacter::Util::Collection') }

  describe "when determining the search path" do
    describe "and the RFACTERLIB environment variable is set" do
      it "should include all paths in RFACTERLIB" do
        allow(ENV).to receive(:include?).with('RFACTERLIB').and_return(true)
        allow(ENV).to receive(:[]).with('RFACTERLIB').and_return(
          "/one/path#{File::PATH_SEPARATOR}/two/path")

        allow(File).to receive(:directory?).and_return(false)
        allow(File).to receive(:directory?).with('/one/path').and_return(true)
        allow(File).to receive(:directory?).with('/two/path').and_return(true)

        allow(subject).to receive(:valid_search_path?).and_return(true)

        expect(subject.search_path).to include('/one/path', '/two/path')
      end
    end
  end

  describe "when loading facts" do
    it "should load any files in the search path with names matching the fact name" do
      allow(subject).to receive(:search_path).and_return(%w{/one/dir /two/dir})
      allow(File).to receive(:file?).and_return(false)
      allow(File).to receive(:file?).with("/one/dir/testing.rb").and_return(true)

      expect(subject).to receive(:load_file).with("/one/dir/testing.rb", collection)

      subject.load(:testing, collection)
    end

    it 'should not load any ruby files from subdirectories matching the fact name in the search path' do
      allow(subject).to receive(:search_path).and_return(%w{/one/dir})

      allow(File).to receive(:file?).and_return(false)
      allow(File).to receive(:file?).with("/one/dir/testing.rb").and_return(true)
      allow(File).to receive(:directory?).with("/one/dir/testing").and_return(true)
      allow(Dir).to receive(:entries).with("/one/dir/testing").and_return(%w{foo.rb bar.rb})
      %w{/one/dir/testing/foo.rb /one/dir/testing/bar.rb}.each do |f|
        allow(File).to receive(:directory?).with(f).and_return(false)
      end

      expect(subject).to receive(:load_file).with("/one/dir/testing.rb", collection)
      expect(subject).to_not receive(:load_file).with("/one/dir/testing/foo.rb", collection)
      expect(subject).to_not receive(:load_file).with("/one/dir/testing/bar.rb", collection)

      subject.load(:testing, collection)
    end

    it "should not load files that don't end in '.rb'" do
      allow(subject).to receive(:search_path).and_return(%w{/one/dir})

      allow(File).to receive(:file?).and_return(false)
      allow(File).to receive(:file?).with("/one/dir/testing.rb").and_return(false)

      expect(File).to receive(:exist?).with("/one/dir/testing").never
      expect(subject).to receive(:load_file).never

      subject.load(:testing, collection)
    end
  end

  describe "when loading all facts" do
    before :each do
      allow(subject).to receive(:search_path).and_return([])
      allow(File).to receive(:directory?).and_return(true)
    end

    it "should load all files in all search paths" do
      allow(subject).to receive(:search_path).and_return(%w{/one/dir /two/dir})

      allow(Dir).to receive(:glob).with('/one/dir/*.rb').and_return(%w{/one/dir/a.rb /one/dir/b.rb})
      allow(Dir).to receive(:glob).with('/two/dir/*.rb').and_return(%w{/two/dir/c.rb /two/dir/d.rb})

      %w{/one/dir/a.rb /one/dir/b.rb /two/dir/c.rb /two/dir/d.rb}.each do |f|
        allow(File).to receive(:file?).with(f).and_return(true)
        expect(subject).to receive(:load_file).with(f, collection)
      end

      subject.load_all(collection)
    end

    it "should not try to load subdirectories of search paths" do
      allow(subject).to receive(:search_path).and_return(%w{/one/dir /two/dir})

      # a.rb is a directory
      allow(Dir).to receive(:glob).with('/one/dir/*.rb').and_return(%w{/one/dir/a.rb /one/dir/b.rb})
      allow(File).to receive(:file?).with('/one/dir/a.rb').and_return(false)
      allow(File).to receive(:file?).with('/one/dir/b.rb').and_return(true)

      expect(subject).to receive(:load_file).with('/one/dir/b.rb', collection)

      # c.rb is a directory
      allow(Dir).to receive(:glob).with('/two/dir/*.rb').and_return(%w{/two/dir/c.rb /two/dir/d.rb})
      allow(File).to receive(:file?).with('/two/dir/c.rb').and_return(false)
      allow(File).to receive(:file?).with('/two/dir/d.rb').and_return(true)

      expect(subject).to receive(:load_file).with('/two/dir/d.rb', collection)

      subject.load_all(collection)
    end

    it "should not raise an exception when a file is unloadable" do
      allow(subject).to receive(:search_path).and_return(%w{/one/dir})

      allow(Dir).to receive(:glob).with('/one/dir/*.rb').and_return(%w{/one/dir/a.rb})
      allow(File).to receive(:file?).with('/one/dir/a.rb').and_return(true)
      allow(File).to receive(:read).with('/one/dir/a.rb').and_return('hello')

      allow(collection).to receive(:instance_eval).with('hello', '/one/dir/a.rb').and_raise(LoadError)
      expect(logger).to receive(:log_exception).with(
        LoadError,
        %r{Error loading fact /one/dir/a.rb})

      expect { subject.load_all(collection) }.to_not raise_error
    end

    it "should only load all facts one time" do
      expect(subject).to receive(:search_path).once

      subject.load_all(collection)
      subject.load_all(collection)
    end
  end

  it "should load facts on the facter search path only once" do
    allow(subject).to receive(:load_file)
    subject.load_all(collection)

    expect(subject).to receive(:load_file).with(/kernel\.rb/).never
    subject.load(:kernel, collection)
  end
end
