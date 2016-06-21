class ZMQ::Context
  getter io_threads
  getter max_sockets

  def self.create(io_threads = IO_THREADS_DFLT, max_sockets = MAX_SOCKETS_DFLT)
    new(io_threads, max_sockets) rescue nil
  end

  def self.create(*socket_types, io_threads = IO_THREADS_DFLT, max_sockets = MAX_SOCKETS_DFLT)
    return unless (ctx = new(io_threads, max_sockets))
    sockets = [] of Socket
    # yield ctx
    sockets = socket_types.map { |socket_type| ctx.socket(socket_type) }

    yield ctx, sockets

    sockets.each(&.close)
    ctx.terminate
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

  def socket(type)
    Socket.new(self, type)
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
