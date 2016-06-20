module ZMQ

  abstract class AbstractMessage
    abstract def address
    abstract def data
    abstract def to_s
    abstract def close
  end

  class Message < AbstractMessage
    getter? closed

    def initialize(message : String? = nil)
      @closed, @pointer = false, LibZMQ::Msg.new

      if message
        LibZMQ.msg_init_data(address, message.to_unsafe.as(Void*), message.size, ->(a, b) { LibC.free(b) }, nil)
      else
        LibZMQ.msg_init address
      end
    end

    def to_s
      String.new(data.as(UInt8*), size)
    end

    def data
      LibZMQ.msg_data address
    end

    def size
      LibZMQ.msg_size address
    end

    def finalize
      close
    end

    def close
      @closed = true
      LibZMQ.msg_close(address)
    end

    def address
      pointerof(@pointer)
    end
  end
end
