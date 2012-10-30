require 'digest/sha1'
require 'digest/sha2'

module Enumerable
  def tee(*procs)
    each { |i| procs.map { |p| p.call i } }
  end
end

class IO
  def chunks(chunk_size=1024)
    Enumerator.new { |y| y << read(chunk_size) until eof? }
  end

  def each_chunk(chunk_size=nil)
    chunks.each { |*args| yield *args }
  end

  def digest_with(digest, chunk_size=nil)
    chunks(chunk_size).each { |chunk| digest << chunk }
    digest
  end

  def sha256(chunk_size=nil)
    digest_with Digest::SHA2.new(256), chunk_size
  end

  def tee(*procs)
    ios = procs.map do |proc|
      FiberChunkedIO.new &proc
    end

    chunks.each do |chunk|
      # for each proc
      # - copy chunk into its dedicated IO stream
      # - resume
      ios.each.with_index do |io, i|
        $stdout.puts "#{i}:#{tell}"
        io.write chunk
        io.resume
      end
    end
    ios.map { |io| io.resume }
  end
end

class FiberChunkedIO
  def initialize(chunk_size=1024, &block)
    @chunk_size = chunk_size
    @chunks = []
    @fiber = Fiber.new do
      @result = block.call self
    end
  end

  def resume
    @fiber.resume
    @result
  end

  def write(chunk)
    if chunk.size > @chunk_size
      raise ArgumentError.new("chunk size mismatch: expected #{@chunk_size}, got #{chunk.size}")
    end

    @chunks << chunk
    chunk.size
  end

  def read(chunk_size)
    unless chunk_size == @chunk_size
      raise ArgumentError.new("chunk size mismatch: expected #{@chunk_size}, got #{chunk_size}")
    end

    @chunks.shift
  end

  def chunks(chunk_size=1024)
    Enumerator.new do |y|
      while chunk = read(chunk_size)
        y << chunk
        Fiber.yield
      end
    end
  end
end

File.open("test") do |f|

  sha1_proc = lambda do |f|
    digest = Digest::SHA1.new
    f.chunks.each { |chunk| digest << chunk }
    digest
  end

  sha2_proc = lambda do |f|
    digest = Digest::SHA2.new(256)
    f.chunks.each { |chunk| digest << chunk }
    digest
  end

  puts_proc = lambda do |f|
    f.chunks.each { |chunk| puts chunk.length }
  end

  p f.tee(sha1_proc, sha2_proc, puts_proc)

end
