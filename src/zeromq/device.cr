module ZMQ
  class Device
    getter device

    def self.create(frontend, backend, capture = nil)
      dev = nil
      begin
        dev = new(frontend, backend, capture)
      rescue ArgumentError
        dev = nil
      end

      dev
    end

    def initialize(frontend : Bool, backend : Bool, capture : ZMQ::Socket = nil)
      [["frontend", frontend], ["backend", backend]].each do |name, socket|
        unless socket.is_a?(ZMQ::Socket)
          raise ArgumentError, "Expected a ZMQ::Socket, not a #{socket.class} as the #{name}"
        end
      end

      LibZMQ.proxy(frontend.socket, backend.socket, capture ? capture.socket : nil)
    end
  end
end
