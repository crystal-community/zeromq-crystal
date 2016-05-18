@[Link("zmq")]
lib LibZMQ
  fun version = zmq_version(major : LibC::Int*, minor : LibC::Int*, patch : LibC::Int*)
  fun errno = zmq_errno : LibC::Int
  fun strerror = zmq_strerror(errnum : LibC::Int) : LibC::Char*

  fun init = zmq_init(io_threads : LibC::Int) : Void*
  fun term = zmq_term(context : Void*) : LibC::Int
  fun ctx_new = zmq_ctx_new : Void*
  fun ctx_destroy = zmq_ctx_destroy(context : Void*) : LibC::Int
  fun ctx_set = zmq_ctx_set(context : Void*, option : LibC::Int, optval : LibC::Int) : LibC::Int
  fun ctx_get = zmq_ctx_get(context : Void*, option : LibC::Int) : LibC::Int

  fun msg_init = zmq_msg_init(msg : Msg*) : LibC::Int
  fun msg_init_size = zmq_msg_init_size(msg : Msg*, size : LibC::SizeT) : LibC::Int
  fun msg_init_data = zmq_msg_init_data(msg : Msg*, data : Void*, size : LibC::SizeT, ffn : (Void*, Void* -> Void), hint : Void*) : LibC::Int
  fun msg_close = zmq_msg_close(msg : Msg*) : LibC::Int
  fun msg_data = zmq_msg_data(msg : Msg*) : Void*
  fun msg_size = zmq_msg_size(msg : Msg*) : LibC::SizeT
  fun msg_move = zmq_msg_move(dest : Msg*, src : Msg*) : LibC::Int
  fun msg_copy = zmq_msg_copy(dest : Msg*, src : Msg*) : LibC::Int
  fun msg_send = zmq_msg_send(msg : Msg*, s : Void*, flags : LibC::Int) : LibC::Int
  fun msg_recv = zmq_msg_recv(msg : Msg*, s : Void*, flags : LibC::Int) : LibC::Int
  fun msg_more = zmq_msg_more(msg : Msg*) : LibC::Int
  fun msg_get = zmq_msg_get(msg : Msg*, property : LibC::Int) : LibC::Int
  fun msg_set = zmq_msg_set(msg : Msg*, property : LibC::Int, optval : LibC::Int) : LibC::Int

  fun msg_gets = zmq_msg_gets(msg : Msg*, property : LibC::Char*) : LibC::Char*

  fun socket = zmq_socket(x0 : Void*, type : LibC::Int) : Void*
  fun setsockopt = zmq_setsockopt(s : Void*, option : LibC::Int, optval : Void*, optvallen : LibC::SizeT) : LibC::Int
  fun getsockopt = zmq_getsockopt(s : Void*, option : LibC::Int, optval : Void*, optvallen : LibC::SizeT*) : LibC::Int
  fun bind = zmq_bind(s : Void*, addr : LibC::Char*) : LibC::Int
  fun connect = zmq_connect(s : Void*, addr : LibC::Char*) : LibC::Int
  fun close = zmq_close(s : Void*) : LibC::Int
  fun unbind = zmq_unbind(s : Void*, addr : LibC::Char*) : LibC::Int
  fun disconnect = zmq_disconnect(s : Void*, addr : LibC::Char*) : LibC::Int
  fun recvmsg = zmq_recvmsg(s : Void*, msg : Msg*, flags : LibC::Int) : LibC::Int
  fun recv = zmq_recv(s : Void*, buf : Void*, len : LibC::SizeT, flags : LibC::Int) : LibC::Int
  fun sendmsg = zmq_sendmsg(s : Void*, msg : Msg*, flags : LibC::Int) : LibC::Int
  fun send = zmq_send(s : Void*, buf : Void*, len : LibC::SizeT, flags : LibC::Int) : LibC::Int

  fun proxy = zmq_proxy(frontend : Void*, backend : Void*, capture : Void*) : LibC::Int

  fun poll = zmq_poll(items : PollItem*, nitems : LibC::Int, timeout : LibC::Long) : LibC::Int

  fun socket_monitor = zmq_socket_monitor(s : Void*, addr : LibC::Char*, events : LibC::Int) : LibC::Int

  # fun proxy_steerable = zmq_proxy_steerable(frontend : Void*, backend : Void*, capture : Void*, control : Void*) : LibC::Int
  # fun has = zmq_has(capability : LibC::Char*) : LibC::Int
  # fun device = zmq_device(type : LibC::Int, frontend : Void*, backend : Void*) : LibC::Int
  # fun sendiov = zmq_sendiov(s : Void*, iov : Void*, count : LibC::SizeT, flags : LibC::Int) : LibC::Int
  # fun recviov = zmq_recviov(s : Void*, iov : Void*, count : LibC::SizeT*, flags : LibC::Int) : LibC::Int
  # fun stopwatch_start = zmq_stopwatch_start : Void*
  # fun stopwatch_stop = zmq_stopwatch_stop(watch_ : Void*) : LibC::ULong
  # fun sleep = zmq_sleep(seconds_ : LibC::Int)
  # fun threadstart = zmq_threadstart(func : (Void* -> Void), arg : Void*) : Void*
  # fun threadclose = zmq_threadclose(thread : Void*)
end
