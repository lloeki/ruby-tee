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
    ios = procs.map { |proc| FiberChunkedIO.new &proc }

    chunks.each do |chunk|
      ios.each do |io|
        io.write chunk
      end
    end
    ios.each { |io| io.close }
    ios.map { |io| io.result }
  end
end

class FiberChunkedIO
  def initialize(chunk_size=1024, &block)
    @chunk_size = chunk_size
    @chunks = []
    @eof = false
    @fiber = Fiber.new do
      @result = block.call self
    end
    @fiber.resume
  end

  # Being a stream, it behaves like IO#eof? and blocks until the other end sends some data or closes it.
  def eof?
    Fiber.yield
    @eof
  end

  def close
    @eof = true
    @fiber.resume
  end

  def result
    @result
  end

  def write(chunk)
    if chunk.size > @chunk_size
      raise ArgumentError.new("chunk size mismatch: expected #{@chunk_size}, got #{chunk.size}")
    end

    @chunks << chunk
    @eof = false
    @fiber.resume
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
      y << read(chunk_size) until eof?
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

  results = f.tee(sha1_proc, sha2_proc, puts_proc)
  p results
  p File.read('sums').lines.map.with_index { |l, i| results[i] == l.split(' ')[0] }

end
