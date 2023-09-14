require "./spec_helper"

STRING        = "boogy-boogy"
PING_ENDPOINT = "inproc://ping_ping_test"

describe ZMQ::Socket do
  context ".create" do
    it "sets a socket" do
      ZMQ::Context.create do |ctx|
        socket = ZMQ::Socket.create(ctx, ZMQ::REQ)
        socket.socket.should_not be_nil
        socket.close
      end
    end

    context "with block" do
      it "creates a socket for a context" do
        ZMQ::Context.create do |ctx|
          ZMQ::Socket.create(ctx, ZMQ::REQ) do |sock|
            sock.should be_a(ZMQ::Socket)
          end
        end
      end
    end
  end

  context "#new" do
    it "sets socket" do
      ZMQ::Context.create do |ctx|
        sock = ZMQ::Socket.new(ctx, ZMQ::REQ)
        sock.socket.should_not be_nil
        sock.close
      end
    end

    it "sets the identity for less than 255 bytes" do
      ctx = ZMQ::Context.new
      sock = ZMQ::Socket.new(ctx, ZMQ::REQ)

      sock.identity = "ab"
      sock.identity.should eq("ab")
      sock.close
      ctx.terminate
    end

    it "do not set the identity for more than 255 bytes" do
      ctx = ZMQ::Context.new
      sock = ZMQ::Socket.new(ctx, ZMQ::REQ)

      sock.identity = "ab" * 150
      sock.identity.should eq("")
      sock.close
      ctx.terminate
    end

    it "convert numeric identities to strings" do
      ctx = ZMQ::Context.new
      sock = ctx.socket(ZMQ::REQ)
      sock.identity = 7
      sock.identity.should eq("7")
      sock.close
      ctx.terminate
    end
  end

  context "socket-options" do
    it "more_parts returns true or false" do
      APIHelper.with_pair_sockets(ZMQ::REQ, ZMQ::REP) do |ping, pong|
        ping.bind PING_ENDPOINT
        APIHelper.connect_to_inproc pong, PING_ENDPOINT

        ping.send_message(ZMQ::Message.new(STRING), ZMQ::SNDMORE).should be_true
        ping.send_message(ZMQ::Message.new(STRING)).should be_true
        pong.receive_message.to_s.should eq(STRING)
        pong.more_parts?.should eq true
        pong.receive_message.to_s.should eq(STRING)
        pong.more_parts?.should eq false
      end
    end
  end

  context "PUSH-PULL" do
    it "receive an exact copy of the sent string directly on one pull socket" do
      string = "boogi-boogi"

      APIHelper.with_pair_sockets(ZMQ::PUSH, ZMQ::PULL) do |push, pull|
        push.identity = "Test-Sender"

        push.bind PING_ENDPOINT
        APIHelper.connect_to_inproc pull, PING_ENDPOINT

        push.send_string string
        received = pull.receive_string # received
        received.should eq(string)
      end
    end

    it "receive an exact copy of the Message data sent directly on one pull socket" do
      string = "boogi-boogi"
      msg = ZMQ::Message.new string

      APIHelper.with_pair_sockets(ZMQ::PUSH, ZMQ::PULL) do |push, pull|
        push.identity = "Test-Sender"

        push.bind PING_ENDPOINT
        APIHelper.connect_to_inproc pull, PING_ENDPOINT

        push.send_message msg
        received = pull.receive_message # received
        received.to_s.should eq(string)
      end
    end

    it "receive a message for each message sent on socket listening with an equal number of sockets pulls messages and is unique per thread" do
      string = "boogi-boogi"
      received = [] of String
      sockets = [] of ZMQ::Socket
      count = 4
      channel = Channel(String).new

      APIHelper.with_context_and_sockets(ZMQ::PUSH, ZMQ::PULL) do |ctx, push, pull|
        push.identity = "Test-Sender"

        push.bind PING_ENDPOINT
        APIHelper.connect_to_inproc pull, PING_ENDPOINT
        # NOTE: make sure all sockets are connected before we do our load-balancing test
        (count - 1).times do
          socket = ctx.socket ZMQ::PULL
          socket.set_socket_option ZMQ::LINGER, 0
          APIHelper.connect_to_inproc(socket, PING_ENDPOINT)
          sockets << socket
        end
        sockets << pull

        sockets.each do |socket|
          spawn do
            buffer = ""
            buffer = socket.receive_string
            socket.close
            channel.send buffer
          end
        end
        count.times { push.send_string(string) }

        Fiber.yield
        count.times { received << channel.receive }

        received.size.should eq count
      end
    end
  end

  context "REQ-REP" do
    it "receive an exact string copy of the string message sent" do
      APIHelper.with_pair_sockets(ZMQ::REQ, ZMQ::REP) do |ping, pong|
        ping.bind PING_ENDPOINT
        APIHelper.connect_to_inproc pong, PING_ENDPOINT

        APIHelper.send_ping(ping, pong, STRING).should eq(STRING)
      end
    end

    pending "generate a EFSM error when sending via the REQ socket twice in a row without an intervening receive operation" do
      APIHelper.with_pair_sockets(ZMQ::REQ, ZMQ::REP) do |ping, pong|
        ping.bind PING_ENDPOINT
        APIHelper.connect_to_inproc pong, PING_ENDPOINT

        APIHelper.send_ping(ping, pong, STRING)
        ping.send_string(STRING).should be_false
        ZMQ::Util.errno.should eq(ZMQ::EFSM)
      end
    end

    it "receive an exact copy of the sent message using Message objects directly" do
      APIHelper.with_pair_sockets(ZMQ::REQ, ZMQ::REP) do |ping, pong|
        ping.bind PING_ENDPOINT
        APIHelper.connect_to_inproc pong, PING_ENDPOINT

        ping.send_message(ZMQ::Message.new(STRING)).should be_true
        pong.receive_message.to_s.should eq(STRING)
      end
    end

    it "receive an exact copy of the sent message using Message objects directly in non-blocking mode" do
      sent_message = ZMQ::Message.new STRING

      APIHelper.with_pair_sockets(ZMQ::REQ, ZMQ::REP) do |ping, pong|
        ping.bind PING_ENDPOINT
        APIHelper.connect_to_inproc pong, PING_ENDPOINT

        APIHelper.poll_it_for_read(pong) do
          ping.send_message(sent_message, ZMQ::DONTWAIT).should be_true
        end

        received_message = pong.receive_message ZMQ::DONTWAIT
        received_message.to_s.should eq(STRING)
      end
    end
  end
end
