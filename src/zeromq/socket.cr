# EventLoop support
# Crystal Update for zmq sockets
class Crystal::LibEvent::EventLoop
  def create_fd_write_event(sock : ZMQ::Socket, edge_triggered : Bool = false)
    flags = LibEvent2::EventFlags::Write
    flags |= LibEvent2::EventFlags::Persist | LibEvent2::EventFlags::ET # we always do this as ZMQ is edge triggers
    event = event_base.new_event(sock.fd, flags, sock) do |_, sflags, data|
      sock_ref = data.as(ZMQ::Socket)
      zmq_events = sock_ref.events
      is_writable = zmq_events & ZMQ::POLLOUT
      if is_writable && sflags.includes?(LibEvent2::EventFlags::Write)
        sock_ref.resume_write
      elsif sflags.includes?(LibEvent2::EventFlags::Timeout)
        sock_ref.resume_write(timed_out: true)
      end
    end
    event
  end

  def create_fd_read_event(sock : ZMQ::Socket, edge_triggered : Bool = false)
    flags = LibEvent2::EventFlags::Read
    flags |= LibEvent2::EventFlags::Persist | LibEvent2::EventFlags::ET # we always do this as ZMQ is edge triggers
    event = event_base.new_event(sock.fd, flags, sock) do |_, sflags, data|
      sock_ref = data.as(ZMQ::Socket)
      zmq_events = sock_ref.events
      is_readable = zmq_events & ZMQ::POLLIN
      if is_readable && sflags.includes?(LibEvent2::EventFlags::Read)
        sock_ref.resume_read
      elsif sflags.includes?(LibEvent2::EventFlags::Timeout)
        sock_ref.resume_read(timed_out: true)
      end
    end
    event
  end
end

module ZMQ
  class Socket
    include IO::Evented
    getter socket
    getter name : String
    getter? closed

    @read_event = Crystal::ThreadLocalValue(Crystal::EventLoop::Event).new
    @write_event = Crystal::ThreadLocalValue(Crystal::EventLoop::Event).new

    def self.create(context : Context, type : Int32, message_type = Message) : self
      new context, type, message_type
    rescue e : ZMQ::ContextError
      STDERR.puts "Failed to allocate context or socket!"
      raise e
    end

    def self.create(context : Context, type : Int32, message_type = Message)
      sock = new context, type, message_type

      yield sock

      sock.close
    rescue e : ZMQ::ContextError
      STDERR.puts "Failed to allocate context or socket!"
    end

    def initialize(context : Context, type : Int32, @message_type = Message)
      context_ptr = context.pointer

      if context_ptr.null?
        raise ContextError.new "zmq_socket", 0, ETERM, "Context pointer was null"
      else
        @socket = LibZMQ.socket context_ptr, type
        if @socket && !@socket.null?
          @closed, @name = false, SocketTypeNameMap[type]
        else
          raise ContextError.new "zmq_socket", 0, ETERM, "Socket pointer was null with: #{Util.error_string}"
        end
      end
    end

    # libevent  support
    private def add_read_event(timeout = @read_timeout)
      event = @read_event.get { Thread.current.scheduler.@event_loop.create_fd_read_event(self, true) }
      event.add timeout
      nil
    end

    private def add_write_event(timeout = @write_timeout)
      event = @write_event.get { Thread.current.scheduler.@event_loop.create_fd_write_event(self, true) }
      event.add timeout
      nil
    end

    def send_string(string, flags = 0)
      part = @message_type.new(string)
      send_message(part, flags)
    end

    def send_strings(strings : Array(String), flags = 0)
      parts = strings.map { |string| @message_type.new(string) }
      send_messages(parts, flags)
    end

    def send_message(message : AbstractMessage, flags = 0)
      # we always send in non block mode and add a wait writable, caller should close the message when done
      loop do
        rc = LibZMQ.msg_send(message.address, @socket, flags | ZMQ::DONTWAIT)
        if rc == -1
          if Util.errno == Errno::EAGAIN.to_i
            wait_writable
          else
            raise Util.error_string
          end
        else
          return Util.resultcode_ok?(rc)
        end
      end
    ensure
      if (writers = @writers.get?) && !writers.empty?
        add_write_event
      end
    end

    def send_messages(messages : Array(AbstractMessage), flags = 0)
      return false if !messages || messages.empty?
      flags = DONTWAIT if dontwait?(flags)

      messages[0..-2].each do |message|
        return false unless send_message(message, (flags | ZMQ::SNDMORE))
      end

      send_message(messages[-1], flags) # NOTE: according to 0mq docs last call should be the default
    end

    def receive_message(flags = 0) : AbstractMessage
      loop do
        message = @message_type.new
        rc = LibZMQ.msg_recv(message.address, @socket, flags | ZMQ::DONTWAIT)
        if rc == -1
          if Util.errno == Errno::EAGAIN.to_i
            wait_readable
          else
            raise Util.error_string
          end
        else
          return message
        end
      end
    ensure
      if (readers = @readers.get?) && !readers.empty?
        add_read_event
      end
    end

    def receive_string(flags = 0)
      receive_message(flags).to_s
    end

    def receive_strings(flags = 0)
      receive_messages(flags).map do |msg|
        str = msg.to_s
        msg.close
        str
      end
    end

    def receive_messages(flags = 0)
      loop do
        messages = [] of AbstractMessage
        message = @message_type.new
        rc = LibZMQ.msg_recv(message.address, @socket, flags | ZMQ::DONTWAIT)
        if rc == -1
          if Util.errno == Errno::EAGAIN.to_i
            wait_readable
          else
            raise Util.error_string
          end
        else
          messages << message
          if more_parts?
            loop do
              message = @message_type.new
              rc = LibZMQ.msg_recv(message.address, @socket, flags)
              if Util.resultcode_ok?(rc)
                messages << message
                return messages unless more_parts?
              else
                message.close
                messages.map(&.close)
                return messages.clear
              end
            end
          else
            return messages
          end
        end
      end
    ensure
      if (readers = @readers.get?) && !readers.empty?
        add_read_event
      end
    end

    def set_socket_option(name, value)
      rc = case
           when INT32_SOCKET_OPTIONS.includes?(name) && value.is_a?(Int32)
             value32 = value.to_i
             LibZMQ.setsockopt(@socket, name, pointerof(value32).as(Void*), sizeof(Int32))
           when INT32_SOCKET_OPTIONS_V4.includes?(name) && value.is_a?(Int32)
             value32 = value.to_i
             LibZMQ.setsockopt @socket, name, pointerof(value32).as(Void*), sizeof(Int32)
           when INT64_SOCKET_OPTIONS.includes?(name) && value.is_a?(Int64)
             value64 = value.to_i64
             LibZMQ.setsockopt(@socket, name, pointerof(value64).as(Void*), sizeof(Int64))
           when STRING_SOCKET_OPTIONS.includes?(name) && value.is_a?(String)
             LibZMQ.setsockopt @socket, name, value.to_unsafe.as(Void*), value.size
           when STRING_SOCKET_OPTIONS_V4.includes?(name) && value.is_a?(String)
             LibZMQ.setsockopt @socket, name, value.to_unsafe.as(Void*), value.size
           else
             raise "Invalid socket option"
           end

      Util.resultcode_ok?(rc)
    end

    def get_socket_option(name)
      value32 = uninitialized Int32
      value64 = uninitialized Int64
      string_value = uninitialized UInt8[255]
      value = case
              when INT32_SOCKET_OPTIONS.includes?(name)
                size = LibC::SizeT.new(4)
                rc = LibZMQ.getsockopt(@socket, name, pointerof(value32).as(Void*), pointerof(size))
                value32
              when INT32_SOCKET_OPTIONS_V4.includes?(name)
                size = LibC::SizeT.new(4)
                rc = LibZMQ.getsockopt(@socket, name, pointerof(value32).as(Void*), pointerof(size))
                value32
              when INT64_SOCKET_OPTIONS.includes?(name)
                size = LibC::SizeT.new(8)
                rc = LibZMQ.getsockopt(@socket, name, pointerof(value64).as(Void*), pointerof(size))
                value64
              when STRING_SOCKET_OPTIONS.includes?(name)
                size = LibC::SizeT.new(255)
                rc = LibZMQ.getsockopt(@socket, name, pointerof(string_value).as(Void*), pointerof(size))
                String.new(string_value.to_unsafe, size)
              when STRING_SOCKET_OPTIONS_V4.includes?(name)
                size = LibC::SizeT.new(255)
                rc = LibZMQ.getsockopt(@socket, name, pointerof(string_value).as(Void*), pointerof(size))
                string_value
              else
                raise "Invalid socket option"
              end

      raise "Socket option failed" unless Util.resultcode_ok?(rc)
      value
    end

    def identity
      get_socket_option(IDENTITY).to_s
    end

    def identity=(value)
      set_socket_option(IDENTITY, value.to_s)
    end

    def more_parts?
      get_socket_option(RCVMORE).as(Int64) > 0
    end

    def dontwait?(flags)
      (DONTWAIT & flags) == DONTWAIT
    end

    def bind(address)
      Util.resultcode_ok? LibZMQ.bind(@socket, address)
    end

    def unbind(address)
      Util.resultcode_ok? LibZMQ.unbind(@socket, address)
    end

    def connect(address)
      Util.resultcode_ok? LibZMQ.connect(@socket, address)
    end

    def disconnect(address)
      Util.resultcode_ok? LibZMQ.disconnect(@socket, address)
    end

    def address
      @socket
    end

    def finalize
      close
    end

    # file descriptor
    def fd
      get_socket_option(ZMQ::FD).as(Int32)
    end

    # event list
    def events
      get_socket_option(ZMQ::EVENTS).as(Int32)
    end

    def close
      @read_event.consume_each &.free
      @write_event.consume_each &.free
      @closed = true
      LibZMQ.close @socket
    end

    # Copied from ::IO itself, since IO::Evented does not have this:
    protected def check_open
      raise IO::Error.new "Closed stream" if closed?
    end
  end
end
