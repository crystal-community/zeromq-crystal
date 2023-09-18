require "./spec_helper"

ENDPOINT = "inproc://nonblocking_test"

def behave_like_a_soket(receiver)
  pending "returns false when there are no message to read" do
    receiver.receive_string(ZMQ::DONTWAIT).should eq("")
    ZMQ::Util.errno.should eq(ZMQ::EAGAIN)
  end

  pending "returns false when there are no messages to read" do
    receiver.receive_messages(ZMQ::DONTWAIT).should eq([] of ZMQ::Message)
    ZMQ::Util.errno.should eq(ZMQ::EAGAIN)
  end
end

def behave_like_a_soket_without_envelopes(sender, receiver)
  pending "read the single message and returns a successful result code" do
    APIHelper.poll_it_for_read(receiver) do
      sender.send_string("test").should be_true
    end

    receiver.receive_messages(ZMQ::DONTWAIT).size.should eq(1)
  end

  pending "read all message parts transmitted and returns a successful result code" do
    APIHelper.poll_it_for_read(receiver) do
      strings = Array.new(10, "test")
      sender.send_strings(strings).should be_true
    end

    receiver.receive_messages(ZMQ::DONTWAIT).size.should eq(10)
  end
end

def behave_like_a_soket_with_envelopes(sender, receiver)
  pending "read the single message and returns a successful result code" do
    APIHelper.poll_it_for_read(receiver) do
      sender.send_string("test").should be_true
    end

    receiver.receive_messages(ZMQ::DONTWAIT).size.should eq(1 + 1) # extra 1 for envelope
  end

  pending "read all message parts transmitted and returns a successful result code" do
    APIHelper.poll_it_for_read(receiver) do
      strings = Array.new(10, "test")
      sender.send_strings(strings).should be_true
    end

    receiver.receive_messages(ZMQ::DONTWAIT).size.should eq(10 + 1) # add 1 for the envelope
  end
end

describe ZMQ::Socket do
  context "PUB-SUB" do
    context "non-blocking #receive_messages where sender binds and receiver connects" do
      APIHelper.with_pair_sockets(ZMQ::PUB, ZMQ::SUB) do |sender, receiver|
        sender.bind ENDPOINT
        APIHelper.connect_to_inproc(receiver, ENDPOINT)

        behave_like_a_soket receiver: receiver
        # behave_like_a_soket_without_envelopes sender: sender, receiver: receiver
      end
    end

    context "non-blocking #receive_messages where sender connects and receiver binds" do
      APIHelper.with_pair_sockets(ZMQ::PUB, ZMQ::SUB) do |sender, receiver|
        receiver.bind ENDPOINT
        APIHelper.connect_to_inproc(sender, ENDPOINT)

        behave_like_a_soket receiver: receiver
        # behave_like_a_soket_without_envelopes sender: sender, receiver: receiver
      end
    end
  end

  # NOTE: To be able to send multiple REQ-REP messagess use XREQ or XREP. Please see last spec context
  context "REQ" do
    context "non-blocking #receive_messages where sender binds and receiver connects" do
      APIHelper.with_pair_sockets(ZMQ::REQ, ZMQ::REP) do |sender, receiver|
        receiver.bind ENDPOINT
        APIHelper.connect_to_inproc(sender, ENDPOINT)

        behave_like_a_soket receiver: receiver
        # behave_like_a_soket_without_envelopes sender: sender, receiver: receiver
      end
    end

    context "non-blocking #receive_messages where sender connects and receiver binds" do
      APIHelper.with_pair_sockets(ZMQ::REQ, ZMQ::REP) do |sender, receiver|
        sender.bind ENDPOINT
        APIHelper.connect_to_inproc(receiver, ENDPOINT)

        behave_like_a_soket receiver: receiver
        # behave_like_a_soket_without_envelopes sender: sender, receiver: receiver
      end
    end
  end

  context "PUSH" do
    context "non-blocking #receive_messages where sender connects and receiver binds" do
      APIHelper.with_pair_sockets(ZMQ::PUSH, ZMQ::PULL) do |sender, receiver|
        receiver.bind ENDPOINT
        APIHelper.connect_to_inproc(sender, ENDPOINT)

        behave_like_a_soket receiver: receiver
        behave_like_a_soket_without_envelopes sender: sender, receiver: receiver
      end
    end

    context "non-blocking #recvmsgs where sender binds and receiver connects" do
      APIHelper.with_pair_sockets(ZMQ::PUSH, ZMQ::PULL) do |sender, receiver|
        sender.bind ENDPOINT
        APIHelper.connect_to_inproc(receiver, ENDPOINT)

        behave_like_a_soket receiver: receiver
        behave_like_a_soket_without_envelopes sender: sender, receiver: receiver
      end
    end
  end

  context "DEALER" do
    context "non-blocking #receive_messages where sender connects and receiver binds" do
      APIHelper.with_pair_sockets(ZMQ::DEALER, ZMQ::ROUTER) do |sender, receiver|
        receiver.bind ENDPOINT
        APIHelper.connect_to_inproc(sender, ENDPOINT)

        behave_like_a_soket receiver: receiver
        behave_like_a_soket_with_envelopes sender: sender, receiver: receiver
      end
    end

    context "non-blocking #recvmsgs where sender binds & receiver connects" do
      APIHelper.with_pair_sockets(ZMQ::DEALER, ZMQ::ROUTER) do |sender, receiver|
        sender.bind ENDPOINT
        APIHelper.connect_to_inproc(receiver, ENDPOINT)

        behave_like_a_soket receiver: receiver
        behave_like_a_soket_with_envelopes sender: sender, receiver: receiver
      end
    end
  end

  context "XREQ" do
    context "non-blocking #receive_messages where sender connects and receiver binds" do
      APIHelper.with_pair_sockets(ZMQ::XREQ, ZMQ::XREP) do |sender, receiver|
        receiver.bind ENDPOINT
        APIHelper.connect_to_inproc(sender, ENDPOINT)

        behave_like_a_soket receiver: receiver
        behave_like_a_soket_with_envelopes sender: sender, receiver: receiver
      end
    end

    context "non-blocking #receive_messages where sender binds and receiver connects" do
      APIHelper.with_pair_sockets(ZMQ::XREQ, ZMQ::XREP) do |sender, receiver|
        sender.bind ENDPOINT
        APIHelper.connect_to_inproc(receiver, ENDPOINT)

        behave_like_a_soket receiver: receiver
        behave_like_a_soket_with_envelopes sender: sender, receiver: receiver
      end
    end
  end
end
