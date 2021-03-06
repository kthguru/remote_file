require_relative 'test_helper'

describe RemoteFiles::File do
  before do
    @s3 = RemoteFiles.add_store(:s3, :class => RemoteFiles::MockStore, :primary => true)
    @cf = RemoteFiles.add_store(:cf, :class => RemoteFiles::MockStore)

    @file = RemoteFiles::File.new('identifier')
  end

  describe '#stored?' do
    it 'should return true if the file is stored anywhere' do
      @file.stored_in << :s3
      @file.stored?.must_equal(true)
    end

    it 'should return false if the file is not stored anywhere' do
      @file.stored_in.clear
      @file.stored?.must_equal(false)
    end
  end

  describe '#stored_everywhere?' do
    it 'should return false if the file is not stored anywhere' do
      @file.stored_in.clear
      @file.stored_everywhere?.must_equal(false)
    end

    it 'should return false if the file only is stored in some of the stores' do
      @file.stored_in.replace([:s3])
      @file.stored_everywhere?.must_equal(false)
    end

    it 'should return true if the file is stored in all stores' do
      @file.stored_in.replace([:s3, :cf])
      @file.stored_everywhere?.must_equal(true)
    end
  end

  describe '#missing_stores' do
    it 'should give an array of store identifiers where the file is not stored' do
      @file.stored_in.replace([:s3])
      @file.missing_stores.must_equal([:cf])
    end
  end

  describe '#url' do
    before do
      @s3.stubs(:url).returns('s3_url')
      @cf.stubs(:url).returns('cf_url')
    end

    describe 'with no arguments' do
      it 'should return the url on the primary store' do
        @file.url.must_equal('s3_url')
      end
    end

    describe 'with a store identifier' do
      it 'should return the url from that store' do
        @file.url(:cf).must_equal('cf_url')
      end
    end
  end

  describe '#current_url' do
    it 'should return the url from the first store where the file is currently stored' do
      @s3.stubs(:url).returns('s3_url')
      @cf.stubs(:url).returns('cf_url')

      @file.stored_in.replace([:s3])
      @file.current_url.must_equal('s3_url')

      @file.stored_in.replace([:cf])
      @file.current_url.must_equal('cf_url')

      @file.stored_in.replace([:cf, :s3])
      @file.current_url.must_equal('s3_url')

      @file.stored_in.replace([])
      @file.current_url.must_be_nil
    end

    describe '::from_url' do
      it 'should return a file from the first store that matches' do
        url = 'http://something'
        @cf.expects(:file_from_url).with(url).returns(@file)
        assert_equal @file, RemoteFiles::File.from_url(url)
      end
    end
  end
end
