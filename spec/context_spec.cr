require "./spec_helper"

describe ZMQ::Context do
  context "#new" do
    it "should init with  IO thread and Max sockets" do
      ctx = ZMQ::Context.new(2, 3)
      ctx.io_threads.should eq(2)
      ctx.terminate
    end

    it "should raise a ContextError exception for negative io threads" do
      expect_raises(ZMQ::ContextError) do
        ZMQ::Context.new(-1)
      end
    end

    it "should default to requesting 1 i/o thread when no argument is passed" do
      ctx = ZMQ::Context.new
      ctx.io_threads.should eq(1)
      ctx.terminate
    end

    it "should set the :pointer accessor to non-nil" do
      ZMQ::Context.new.pointer.should_not be_nil
    end

    it "should set the context to nil when terminating the library's context" do
      ctx = ZMQ::Context.new # can't use a shared context here because we are terminating it!
      ctx.terminate.should eq(0)
    end
  end

  context "#create" do
    it "should return nil for negative io threads" do
      ZMQ::Context.create(-1).should eq(nil)
    end
  end
end
