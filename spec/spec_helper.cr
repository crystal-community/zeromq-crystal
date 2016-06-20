require "spec"
require "../src/zeromq"

module APIHelper
  extend self

  HELPER_POLLER = ZMQ::Poller.new

  def send_ping(ping, pong, string)
    ping.send_string string
    pong.receive_string
  end

  def with_pair_sockets(first_socket_type = ZMQ::PUSH, last_socket_type = ZMQ::PULL)
    with_context_and_sockets(first_socket_type, last_socket_type) { |ctx, first, last| yield first, last }
  end

  def with_context_and_sockets(first_socket_type = ZMQ::PUSH, last_socket_type = ZMQ::PULL)
    ctx   = ZMQ::Context.new
    first = ctx.socket first_socket_type
    last  = ctx.socket last_socket_type

    yield ctx, first, last

    [first, last].each { |sock| sock.close }
    ctx.terminate
  end

  def connect_to_inproc(socket : ZMQ::Socket, endpoint : String, timeout = 3)
    started = Time.now
    loop do
      break if socket.connect(endpoint) || (started - Time.now).seconds > timeout # ZMQ::Util.resultcode_ok?(rc)
    end
  end

  def poller_register_socket(socket : ZMQ::Socket)
    HELPER_POLLER.register(socket, ZMQ::POLLIN)
  end

  def poll_delivery
    # timeout after 1 second
    HELPER_POLLER.poll(100)
  end

  def poll_it_for_read(socket : ZMQ::Socket, &blk)
    poller_register_socket(socket)
    blk.call
    poll_delivery
  end

  # generate a random port between 10_000 and 65534
  def random_port
    rand(55534) + 10_000
  end

  def bind_to_random_tcp_port(socket, max_tries = 500)
    rc, port = nil, nil
    max_tries.times do
      break if rc = socket.connect(local_transport_string(port = random_port)) # !ZMQ::Util.resultcode_ok?(rc)
    end

    unless rc
      raise "Could not connect to random port successfully; retries all failed!"
    end

    port
  end

  def connect_to_random_tcp_port(socket : ZMQ::Socket, max_tries = 500)
    rc, port = nil, nil
    max_tries.times do
      break if rc = socket.connect(local_transport_string(port = random_port))
    end

    raise "Could not connect to random port successfully; retries all failed!" unless rc

    port
  end

  def local_transport_string(port)
    "tcp://127.0.0.1:#{port}"
  end

  def assert_ok(rc)
    raise "Failed with rc [#{rc}] and errno [#{ZMQ::Util.errno}], msg [#{ZMQ::Util.error_string}]! #{caller(0)}" unless rc >= 0
  end
end
