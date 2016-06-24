require "./spec_helper"

describe ZMQ::Context do
  context "#socket" do
    it "create new socket in the given context" do
      ZMQ::Context.create do |ctx|
        sock = ctx.socket(ZMQ::REQ)
        sock.should be_a ZMQ::Socket
        sock.name.should eq("REQ")
        sock.close
      end
    end

    context "with block" do
      it "creates a socket for a context" do
        ZMQ::Context.create do |ctx|
          ctx.socket ZMQ::REQ do |sock|
            sock.should be_a(ZMQ::Socket)
          end
        end
      end
    end
  end

  context "#new" do
    it "init with  IO thread and Max sockets" do
      ctx = ZMQ::Context.new(2, 3)
      ctx.io_threads.should eq(2)
      ctx.terminate
    end

    it "raise a ContextError exception for negative io threads" do
      expect_raises(ZMQ::ContextError) do
        ZMQ::Context.new(-1)
      end
    end

    it "default to requesting 1 i/o thread when no argument is passed" do
      ctx = ZMQ::Context.new
      ctx.io_threads.should eq(1)
      ctx.terminate
    end

    it "set the :pointer accessor to non-nil" do
      ZMQ::Context.new.pointer.should_not be_nil
    end

    it "set the context to nil when terminating the library's context" do
      ctx = ZMQ::Context.new # can't use a shared context here because we are terminating it!
      ctx.terminate.should eq(0)
    end
  end

  context "#create" do
    it "return self" do
      ZMQ::Context.create.should be_a ZMQ::Context
    end

    context "with block" do
      it "creates a context" do
        ZMQ::Context.create do |ctx|
          ctx.should be_a(ZMQ::Context)
        end
      end

      it "creates a context and sockets" do
        ZMQ::Context.create(ZMQ::PUSH, ZMQ::PULL) do |ctx, sockets|
          ctx.should  be_a(ZMQ::Context)
          push, pull = sockets
          push.should be_a(ZMQ::Socket)
          pull.should be_a(ZMQ::Socket)
          sockets.size.should eq(2)
          sockets.each { |socket| socket.should be_a(ZMQ::Socket) }
        end
      end
    end
  end
end
