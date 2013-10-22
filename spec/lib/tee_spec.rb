require 'spec_helper'
require 'tee'
require 'tee/core_ext'

describe IO::Chunkable do
  let(:io) do
    Class.new do
      def initialize
        @count = -1
      end

      def read(bytes)
        @count += 1
        @count.to_s[0] * bytes
      end

      def eof?
        @count > 10
      end
    end.new
       .extend(IO::Chunkable)
  end

  it 'should allow enumeration of chunks' do
    io.chunks.should be_a Enumerator
  end

  it 'should allow iteration on chunks' do
    io.each_chunk.with_index do |chunk, i|
      chunk.length.should eq 1024
      chunk[0].should eq i.to_s[0]
    end

    io.each_chunk do |chunk|
      chunk.length.should eq 1024
    end
  end
end

describe IO::Digestable do
  let(:io) do
    Class.new do
      def initialize
        @count = -1
      end

      def read(bytes)
        @count += 1
        @count.to_s[0] * bytes
      end

      def eof?
        @count > 10
      end
    end.new
       .extend(IO::Chunkable)
       .extend(IO::Digestable)
  end

  let(:digest) do
    Class.new do
      def initialize
        @digest = 0
      end

      attr_reader :digest

      def <<(value)
        @digest += value.each_byte.reduce(0) { |a, e| a + e }
      end
    end.new
  end

  it 'should digest the whole IO with the provided hash functions' do
    io.digest_with(digest).digest.should eq 637_952
  end

  it 'should digest the whole IO with sha256' do
    io.sha256.hexdigest.should eq '56e2d8a90ae93b2637ab8e005243580d'\
                                  'a87b03d8dc32d0b9a5aaaeb39ae6bd48'
  end

  it 'should digest the whole IO with typical hash functions'

  it 'should do a rolling digest with the provided digest'
  it 'should do a rolling digest with typical hash functions'
end

describe FiberChunkedIO do
  it 'should tee a file in chunks' do
    File.open(fixture 'lorem') do |lorem|

      sha1_proc = lambda do |f|
        f.chunks.each.with_object(Digest::SHA1.new) do |chunk, digest|
          digest << chunk
        end
      end

      sha2_proc = lambda do |f|
        f.chunks.each.with_object(Digest::SHA2.new(256)) do |chunk, digest|
          digest << chunk
        end
      end

      chunk_sizes = []
      chunk_sizes_proc = lambda do |f|
        f.chunks.each { |chunk| chunk_sizes << chunk.length }
      end

      results = lorem.tee(sha1_proc, sha2_proc, chunk_sizes_proc)

      results.size.should eq 3
      chunk_sizes.should eq [1024, 1024, 1024, 1024, 918]

      File.read(fixture 'sums').lines
          .map.with_index do |l, i|
        results[i].should eq l.split(' ')[0]
      end
    end
  end
end
