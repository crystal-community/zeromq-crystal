module ZMQ
  class Message
    def initialize(message : String? = nil)
      @pointer = LibZMQ::Msg.new

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

    def close
      LibZMQ.msg_close(address)
    end

    def address
      pointerof(@pointer)
    end
  end
end
