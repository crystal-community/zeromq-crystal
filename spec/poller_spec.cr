require "./spec_helper"

POLLER_ENDPOINT = "inproc://poll_test"

describe ZMQ::Poller do
  context "#register" do
    it "returns false when given a nil pollable" do
      poller = ZMQ::Poller.new
      ZMQ::Context.create(ZMQ::DEALER) do |ctx, (pollable)|
        orig = poller.poll_items.size
        poller.register(pollable, ZMQ::POLLIN)
        poller.poll_items.size.should eq(orig + 1)
      end
    end
  end

  context "#poll" do
    it "returns 0 when there are no sockets to poll" do
      poller = ZMQ::Poller.new
      poller.poll(1).should eq(0)
    end

   it "returns 0 when there is a single socket to poll and no events" do
      poller = ZMQ::Poller.new
      ZMQ::Context.create(ZMQ::DEALER) do |ctx, (first)|
        poller.register(first, ZMQ::POLLIN)
        poller.poll(1).should eq(0)
      end
    end

    it "returns 1 when there is a read event on a socket" do
      poller = ZMQ::Poller.new
      ZMQ::Context.create(ZMQ::DEALER, ZMQ::ROUTER) do |ctx, (first, last)|
        first.bind POLLER_ENDPOINT
        APIHelper.connect_to_inproc last, POLLER_ENDPOINT

        poller.register_readable last
        first.send_string "test"

        poller.poll(1).should eq(1)
      end
    end
  end
end
