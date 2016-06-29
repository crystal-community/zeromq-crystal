class ZMQ::Context
  getter io_threads
  getter max_sockets

  def self.create(io_threads = IO_THREADS_DFLT, max_sockets = MAX_SOCKETS_DFLT) : self
    new(io_threads, max_sockets)
  end

  def self.create(*socket_types, io_threads = IO_THREADS_DFLT, max_sockets = MAX_SOCKETS_DFLT)
    ctx = new io_threads, max_sockets
    sockets = ctx.sockets(*socket_types)
    
    yield ctx, sockets

    sockets.each(&.close)
    ctx.terminate
  rescue e : ZMQ::ContextError
    STDERR.puts "Failed to allocate context or socket!"
    raise e
  end

  def initialize(@io_threads = IO_THREADS_DFLT, @max_sockets = MAX_SOCKETS_DFLT)
    @sockets = [] of Socket
    @context = LibZMQ.ctx_new
    ZMQ::Util.error_check "zmq_ctx_new", (@context.null?) ? -1 : 0

    rc = LibZMQ.ctx_set(@context, ZMQ::IO_THREADS, @io_threads)
    ZMQ::Util.error_check "zmq_ctx_set", rc

    rc = LibZMQ.ctx_set(@context, ZMQ::MAX_SOCKETS, @max_sockets)
    ZMQ::Util.error_check "zmq_ctx_set", rc
  end

  def terminate
    if @context.null?
      0
    else
      LibZMQ.ctx_destroy(@context)
    end
  end

  def sockets(*types)
    types.map { |type| socket(type) }
  end

  def sockets(*types)
    sockets = sockets(*types)

    yield sockets

    sockets.each &.close
  end

  def socket(type)
    Socket.new(self, type)
  end

  def socket(type)
    socket_instance = Socket.new(self, type)

    yield socket_instance

    socket_instance.close
  end

  def pointer
    @context
  end

  def finalize
    self.class.close(@context, Process.pid)
  end

  def self.close(context, pid)
    ->{ LibZMQ.term context if Process.pid == pid }
  end
end
