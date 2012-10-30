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

  def fiber_chunks(chunk_size=1024)
    Enumerator.new do |y|
      until eof?
        Fiber.yield
        y << read(chunk_size)
      end
    end
  end

  def tee(*procs)
    results = procs.map { nil }
    ios = procs.map do |proc|
      #IO.new
      self
    end
    fibers = procs.map.with_index do |proc, i|
      # set up communication
      # start each proc, which will yield just before reading
      Fiber.new do
        results[i] = proc.call ios[i]
      end
    end.each { |fiber| fiber.resume }
    prev_pos = tell
    chunks.each do |chunk|
      new_pos = tell
      # for each proc
      # - copy chunk into its dedicated IO stream
      # - resume
      procs.each.with_index do |proc, i|
        ios[i].seek prev_pos
        #ios[i].write chunk
        fibers[i].resume
        ios[i].seek new_pos
      end
      prev_pos = new_pos
    end
    results
  end
end


File.open("tee.rb") do |f|

  sha1_proc = lambda do |f|
    digest = Digest::SHA1.new
    f.fiber_chunks.each { |chunk| digest << chunk }
    digest
  end

  sha2_proc = lambda do |f|
    digest = Digest::SHA2.new(256)
    f.fiber_chunks.each { |chunk| digest << chunk }
    digest
  end

  puts_proc = lambda do |f|
    f.fiber_chunks.each { |chunk| puts chunk }
  end

  p f.tee(sha1_proc, sha2_proc, puts_proc)

end
