require "spec"
require "../src/zeromq"

module APIHelper
  extend self

  HELPER_POLLER = ZMQ::Poller.new

  def send_ping(ping, pong, string)
    ping.send_string string
    pong.receive_string
  end

  def with_req_rep(endpoint = "inproc://reqrep_test", req_type = ZMQ::REQ, rep_type = ZMQ::REP)
    ctx  = ZMQ::Context.new

    req = ctx.socket req_type
    rep = ctx.socket rep_type

    req.identity = "req"
    rep.identity = "rep"

    rep.bind(endpoint)
    connect_to_inproc(req, endpoint)

    yield ctx, req, rep, endpoint

    [req, rep].each { |sock| sock.close }
    ctx.terminate
  end

  def with_push_pull(link = "inproc://push_pull_test")
    string = "boogi-boogi"
    msg = ZMQ::Message.new string

    ctx = ZMQ::Context.new
    push = ctx.socket ZMQ::PUSH
    pull = ctx.socket ZMQ::PULL

    push.bind link
    connect_to_inproc pull, link

    yield ctx, push, pull, link

    [push, pull].each { |sock| sock.close }
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

  def poller_deregister_socket(socket)
  end

  def poll_delivery
    # timeout after 1 second
    HELPER_POLLER.poll(1000)
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
