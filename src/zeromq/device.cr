module ZMQ
  class Device
    getter device

    def self.create(frontend, backend, capture = nil)
      new(frontend, backend, capture)
    end

    def initialize(frontend : ZMQ::Socket, backend : ZMQ::Socket, capture : ZMQ::Socket? = nil)
      @device = LibZMQ.proxy(frontend.socket, backend.socket, capture ? capture.socket : nil)
    end
  end
end
