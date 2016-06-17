require "./spec_helper"

ENDPOINT = "inproc://nonblocking_test"

def behave_like_a_soket(receiver)
  it "returns false when there are no message to read" do
    receiver.receive_string(ZMQ::DONTWAIT).should eq("")
    ZMQ::Util.errno.should eq(ZMQ::EAGAIN)
  end

  it "returns false when there are no messages to read" do
    receiver.receive_messages(ZMQ::DONTWAIT).should eq([] of ZMQ::Message)
    ZMQ::Util.errno.should eq(ZMQ::EAGAIN)
  end
end

def behave_like_a_soket_without_envelopes(sender, receiver)
  it "read the single message and returns a successful result code" do
    APIHelper.poll_it_for_read(receiver) do
      sender.send_string("test").should be_true
    end

    receiver.receive_messages(ZMQ::DONTWAIT).size.should eq(1)
  end

  it "read all message parts transmitted and returns a successful result code" do
    APIHelper.poll_it_for_read(receiver) do
      strings = Array.new(10, "test")
      sender.send_strings(strings).should be_true # puts ZMQ::Util.error_string unless sender.send_strings(strings)
    end

    receiver.receive_messages(ZMQ::DONTWAIT).size.should eq(10)
  end
end

def behave_like_a_soket_with_envelopes(sender, receiver)
  it "read the single message and returns a successful result code" do
    APIHelper.poll_it_for_read(receiver) do
      sender.send_string("test").should be_true
    end

    receiver.receive_messages(ZMQ::DONTWAIT).size.should eq(1 + 1) # extra 1 for envelope
  end

  it "read all message parts transmitted and returns a successful result code" do
    APIHelper.poll_it_for_read(receiver) do
      strings = Array.new(10, "test")
      sender.send_strings(strings).should be_true
      # puts Util.error_string unless sender.send_strings(strings)
    end

    receiver.receive_messages(ZMQ::DONTWAIT).size.should eq(10 + 1) # add 1 for the envelope
  end
end

describe ZMQ::Socket do
  context "PUB-SUB" do
    context "non-blocking #receive_messages where sender binds and receiver connects" do
      APIHelper.with_pub_sub do |sender, receiver|
        behave_like_a_soket receiver: receiver
        behave_like_a_soket_without_envelopes sender: sender, receiver: receiver
      end
    end

    context "non-blocking #receive_messages where sender connects and receiver binds" do
      # NOTE in order to reverce bind and connect we reverce types and argument places
      APIHelper.with_pub_sub(pub_type: ZMQ::SUB, sub_type: ZMQ::PUB) do |receiver, sender|
        behave_like_a_soket receiver: receiver
      end
    end
  end

  context "REQ" do
     context "non-blocking #receive_messages where sender binds and receiver connects" do
      # NOTE in order to reverce bind and connect we reverce types and argument places
      APIHelper.with_req_rep(req_type: ZMQ::REP, rep_type: ZMQ::REQ) do |ctx, receiver, sender|
        behave_like_a_soket receiver: receiver
        # NOTE: currently gives error: Operation cannot be accomplished in current state
        # behave_like_a_soket_without_envelopes sender: sender, receiver: receiver
      end
    end

    context "non-blocking #receive_messages where sender connects and receiver binds" do
      APIHelper.with_req_rep do |ctx, sender, receiver|
        behave_like_a_soket receiver: receiver
        # NOTE: currently gives error: Operation cannot be accomplished in current state
        # behave_like_a_soket_without_envelopes sender: sender, receiver: receiver
      end
    end
  end

  context "PUSH" do
    context "non-blocking #receive_messages where sender connects and receiver binds" do
      APIHelper.with_push_pull(push_type: ZMQ::PULL, pull_type: ZMQ::PUSH) do |ctx, receiver, sender|
        behave_like_a_soket receiver: receiver
        behave_like_a_soket_without_envelopes sender: sender, receiver: receiver
      end
    end

    context "non-blocking #recvmsgs where sender binds and receiver connects" do
      APIHelper.with_push_pull do |ctx, sender, receiver|
        behave_like_a_soket receiver: receiver
        behave_like_a_soket_without_envelopes sender: sender, receiver: receiver
      end
    end
  end

  context "DEALER" do
    context "non-blocking #receive_messages where sender connects and receiver binds" do
      APIHelper.with_router_dealer do |sender, receiver|
        behave_like_a_soket receiver: receiver
        behave_like_a_soket_with_envelopes sender: sender, receiver: receiver
      end
    end

    context "non-blocking #recvmsgs where sender binds & receiver connects" do
      APIHelper.with_router_dealer(router_type: ZMQ::DEALER, dealer_type: ZMQ::ROUTER) do |receiver, sender|
        behave_like_a_soket receiver: receiver
        behave_like_a_soket_with_envelopes sender: sender, receiver: receiver
      end
    end
  end

  context "XREQ" do
    context "non-blocking #receive_messages where sender connects and receiver binds" do
      APIHelper.with_pair_sockets(first_socket_type: ZMQ::XREQ, last_socket_type: ZMQ::XREP) do |sender, receiver|
        receiver.bind ENDPOINT
        APIHelper.connect_to_inproc(sender, ENDPOINT)

        behave_like_a_soket receiver: receiver
        behave_like_a_soket_with_envelopes sender: sender, receiver: receiver
      end
    end

    context "non-blocking #receive_messages where sender binds and receiver connects" do
      APIHelper.with_pair_sockets(first_socket_type: ZMQ::XREQ, last_socket_type: ZMQ::XREP) do |sender, receiver|
        sender.bind ENDPOINT
        APIHelper.connect_to_inproc(receiver, ENDPOINT)

        behave_like_a_soket receiver: receiver
        behave_like_a_soket_with_envelopes sender: sender, receiver: receiver
      end
    end
  end
end
