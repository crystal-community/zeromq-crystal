require "./spec_helper"

describe ZMQ::Context do
  context "#sockets" do
    it "create new sockets in the given context" do
      ZMQ::Context.create do |ctx|
        req, rep = ctx.sockets(ZMQ::REQ, ZMQ::REP)

        req.should be_a ZMQ::Socket
        req.name.should eq("REQ")
        req.socket.null?.should be_false

        rep.should be_a ZMQ::Socket
        rep.name.should eq("REP")
        rep.socket.null?.should be_false

        req.close
        rep.close
      end
    end

    context "with block" do
      it "creates sockets for a context" do
        ZMQ::Context.create do |ctx|
          ctx.sockets ZMQ::REQ, ZMQ::REP do |req, rep|
            req.should be_a(ZMQ::Socket)
            req.name.should eq("REQ")
            req.socket.null?.should be_false

            rep.should be_a ZMQ::Socket
            rep.name.should eq("REP")
            rep.socket.null?.should be_false
          end
        end
      end
    end
  end

  context "#socket" do
    it "create new socket in the given context" do
      ZMQ::Context.create do |ctx|
        sock = ctx.socket(ZMQ::REQ)
        sock.should be_a ZMQ::Socket
        sock.name.should eq("REQ")
        sock.socket.null?.should be_false
        sock.close
      end
    end

    context "with block" do
      it "creates a socket for a context" do
        ZMQ::Context.create do |ctx|
          ctx.socket ZMQ::REQ do |sock|
            sock.should be_a(ZMQ::Socket)
            sock.name.should eq("REQ")
            sock.socket.null?.should be_false
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
          ctx.pointer.null?.should be_false
        end
      end

      it "creates a context and sockets" do
        ZMQ::Context.create(ZMQ::PUSH, ZMQ::PULL) do |ctx, (push, pull)|
          ctx.should  be_a(ZMQ::Context)
          ctx.pointer.null?.should be_false

          push.should be_a(ZMQ::Socket)
          push.socket.null?.should be_false
          push.name.should eq("PUSH")

          pull.should be_a(ZMQ::Socket)
          pull.socket.null?.should be_false
          pull.name.should eq("PULL")
        end
      end
    end
  end
end
