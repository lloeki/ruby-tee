require 'tee'

class IO
  include Chunkable
  include Digestable
  include Tee
end

class StringIO
  include IO::Chunkable
  include IO::Digestable
  include IO::Tee
end

module Enumerable
  def tee(*procs)
    Enumerable::Tee.instance_method(:tee).bind(self).call(*procs)
  end
end
