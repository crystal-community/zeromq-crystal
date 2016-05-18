class ZMQ::Socket(T)
  getter socket
  getter name : String
  getter? closed

  def initialize(context : ZMQ::Context, type : Int32)
    context_ptr = context.pointer

    if context_ptr.null?
      raise ContextError.new "zmq_socket", 0, ETERM, "Context pointer was null"
    else
      @socket = LibZMQ.socket context_ptr, type
      @closed = false
      if @socket && !@socket.null?
        @name = SocketTypeNameMap[type]
      else
        raise ContextError.new "zmq_socket", 0, ETERM, "Socket pointer was null"
      end
    end
  end

  def send_string(string, flags = 0)
    part = Message.new(string)
    send_message(part, flags)
  end

  def send_strings(strings : Array(String), flags = 0)
    parts = strings.map { |string| Message.new(string) }
    send_messages(parts, flags)
  end

  def send_message(message, flags = 0)
    rc = LibZMQ.sendmsg(@socket, message.address, flags)
    message.close
    Util.resultcode_ok?(rc)
  end

  def send_messages(messages : Array(Message), flags = 0)
    if !messages || messages.empty?
      -1
    else
      flags = DONTWAIT if dontwait?(flags)
      rc = 0

      messages[0..-2].each do |message|
        rc = send_message(message, (flags | ZMQ::SNDMORE))
        break unless Util.resultcode_ok?(rc)
      end

      Util.resultcode_ok?(rc) ? send_message(messages[-1], flags) : rc
    end
  end

  def receive_message(flags = 0)
    message = T.new
    LibZMQ.recvmsg(@socket, message.address, flags)
    message
  end

  def receive_string(flags = 0)
    receive_message(flags).to_s
  end

  def receive_strings(flags = 0)
    receive_messages.map(&.to_s)
  end

  def receive_messages(flags = 0)
    messages = [] of Message

    message = T.new
    rc = LibZMQ.recvmsg(@socket, message.address, flags)

    if Util.resultcode_ok?(rc)
      messages << message
      while Util.resultcode_ok?(rc) && more_parts?
        message = T.new
        rc = LibZMQ.recvmsg(@socket, message.address, flags)

        if Util.resultcode_ok?(rc)
          messages << message
        else
          message.close
          messages.map(&.close)
          messages.clear
        end
      end
    else
      message.close
    end
    messages
  end

  def set_socket_option(name, value)
    rc = case
         when INT32_SOCKET_OPTIONS.includes?(name) && value.is_a?(Number)
           value = value.to_i
           LibZMQ.setsockopt @socket, name, pointerof(value).as(Void*), sizeof(Int32)
         when INT32_SOCKET_OPTIONS_V4.includes?(name) && value.is_a?(Number)
           value = value.to_i
           LibZMQ.setsockopt @socket, name, pointerof(value).as(Void*), sizeof(Int32)
         when INT64_SOCKET_OPTIONS.includes?(name) && value.is_a?(Number)
           value = value.to_i64
           LibZMQ.setsockopt @socket, name, pointerof(value).as(Void*), sizeof(Int64)
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
    get_socket_option RCVMORE
  end

  def dontwait?(flags)
    (DONTWAIT & flags) == DONTWAIT
  end

  def bind(address)
    Util.resultcode_ok? LibZMQ.bind @socket, address
  end

  def unbind(address)
    Util.resultcode_ok? LibZMQ.unbind @socket, address
  end

  def connect(address)
    Util.resultcode_ok? LibZMQ.connect @socket, address
  end

  def disconnect(address)
    Util.resultcode_ok? LibZMQ.disconnect @socket, address
  end

  def address
    @socket
  end

  def finalize
    close
  end

  def close
    @close = true
    LibZMQ.close @socket
  end
end
