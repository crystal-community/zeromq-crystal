require "./spec_helper"

describe ZMQ::Socket do
  context "#send_strings" do
    it "correctly handles a multipart message with single message send" do
      data = { "topic", "payload" } # [ "1" ]
      APIHelper.with_push_pull("tcp://127.0.0.1:5555") do |ctx, sender, receiver|
        sender.identity = "Test-Sender"
        sender.send_string(sender.identity, ZMQ::SNDMORE)
        sender.send_string(data[0], ZMQ::SNDMORE)
        sender.send_string(data[1])
        # sender.send_strings(data)
        sleep 0.1
        # receiver.receive_strings.should eq(data)
        receiver.receive_string.should eq(sender.identity)
        receiver.more_parts?.should be_truthy

        receiver.receive_string.should eq(data[0])
        receiver.more_parts?.should be_truthy

        receiver.receive_string.should eq(data[1])
        receiver.more_parts?.should be_falsey
      end
    end

    it "correctly handles a multipart message with multiple recieve" do
      data = { "topic", "payload" } # [ "1" ]
      APIHelper.with_push_pull("tcp://127.0.0.1:5555") do |ctx, sender, receiver|
        sender.identity = "Test-Sender"
        sender.send_string(sender.identity, ZMQ::SNDMORE)
        sender.send_string(data[0], ZMQ::SNDMORE)
        sender.send_string(data[1])
        sleep 0.1
        receiver.receive_strings.should eq [sender.identity, data[0], data[1]]
      end
    end

    it "correctly handles a multipart message with single string array" do
      data = [ "1" ]
      APIHelper.with_push_pull("tcp://127.0.0.1:5555") do |ctx, sender, receiver|
        sender.send_strings(data)
        sleep 0.1
        receiver.receive_strings.should eq data
      end
    end

    it "delivers between REQ and REP returning an array of messages" do
      req_data, rep_data = [ "1", "2" ], [ "2", "3" ]
      APIHelper.with_req_rep("tcp://127.0.0.1:5555") do |ctx, req, rep|
        req.send_strings(req_data)
        rep.receive_messages.each_with_index do |msg, idx|
         msg.to_s.should eq(req_data[idx])
        end

        rep.send_strings(rep_data)
        req.receive_messages.each_with_index do |msg, idx|
          msg.to_s.should eq(rep_data[idx])
        end
      end
    end

    it "delivers between REQ and REP returning an array of strings" do
      req_data, rep_data = [ "1", "2" ], [ "2", "3" ]
      APIHelper.with_req_rep do |ctx, req, rep|
        req.send_strings(req_data)
        rep.receive_strings.should eq(req_data)

        rep.send_strings(rep_data)
        req.receive_strings.should eq(rep_data)
      end
    end
  end

  context "with identity" do
    it "delivers between REQ and REP returning an array of strings with an empty string as the envelope delimiter" do
      APIHelper.with_req_rep(rep_type: ZMQ::XREP) do |ctx, req, rep|
        req_data, rep_data = "hello", [ req.identity, "", "ok" ]

        req.send_string(req_data)
        rep.receive_strings.should eq([ req.identity, "", "hello" ])

        rep.send_strings(rep_data)
        req.receive_string.should eq(rep_data.last)
      end
    end

    it "delivers between REQ and REP returning an array of of messages with an empty string as the envelope delimiter" do
      APIHelper.with_req_rep(rep_type: ZMQ::XREP) do |ctx, req, rep|
        req_data, rep_data = "hello", [ req.identity, "", "ok" ]

        req.send_string(req_data)
        rep.receive_messages.map(&.to_s).should eq([ req.identity, "", "hello" ])

        rep.send_strings(rep_data)
        req.receive_messages.first.to_s.should eq(rep_data.last)
      end
    end
  end
end
