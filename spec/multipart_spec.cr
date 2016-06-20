require "./spec_helper"

MULTIPART_ENDPOINT = "inproc://multipart_test"

describe ZMQ::Socket do
  context "#send_strings" do
    it "correctly handles a multipart message with single message send" do
      data = { "topic", "payload" }

      APIHelper.with_pair_sockets(ZMQ::PUSH, ZMQ::PULL) do |sender, receiver|
        sender.identity = "Test-Sender"

        sender.bind MULTIPART_ENDPOINT
        APIHelper.connect_to_inproc receiver, MULTIPART_ENDPOINT

        sender.send_string(sender.identity, ZMQ::SNDMORE)
        sender.send_string(data[0], ZMQ::SNDMORE)
        sender.send_string(data[1])

        receiver.receive_string.should eq(sender.identity)
        receiver.more_parts?.should be_truthy

        receiver.receive_string.should eq(data[0])
        receiver.more_parts?.should be_truthy

        receiver.receive_string.should eq(data[1])
        receiver.more_parts?.should be_falsey
      end
    end

    it "correctly handles a multipart message with multiple recieve" do
      data = { "topic", "payload" }
      
      APIHelper.with_pair_sockets(ZMQ::PUSH, ZMQ::PULL) do |sender, receiver|
        sender.identity = "Test-Sender"
        sender.bind MULTIPART_ENDPOINT
        APIHelper.connect_to_inproc receiver, MULTIPART_ENDPOINT

        sender.send_string(sender.identity, ZMQ::SNDMORE)
        sender.send_string(data[0], ZMQ::SNDMORE)
        sender.send_string(data[1])
        receiver.receive_strings.should eq [sender.identity, data[0], data[1]]
      end
    end

    it "correctly handles a multipart message with single string array" do
      data = [ "1" ]

      APIHelper.with_pair_sockets(ZMQ::PUSH, ZMQ::PULL) do |sender, receiver|
        sender.bind MULTIPART_ENDPOINT
        APIHelper.connect_to_inproc receiver, MULTIPART_ENDPOINT

        sender.send_strings(data)
        receiver.receive_strings.should eq data
      end
    end

    it "delivers between REQ and REP returning an array of messages" do
      req_data, rep_data = [ "1", "2" ], [ "2", "3" ]

      APIHelper.with_pair_sockets(ZMQ::REQ, ZMQ::REP) do |req, rep|
        req.bind MULTIPART_ENDPOINT
        APIHelper.connect_to_inproc rep, MULTIPART_ENDPOINT

        req.send_strings(req_data)
        rep.receive_messages.each_with_index { |msg, idx| msg.to_s.should eq(req_data[idx]) }

        rep.send_strings(rep_data)
        req.receive_messages.each_with_index { |msg, idx| msg.to_s.should eq(rep_data[idx]) }
      end
    end

    it "delivers between REQ and REP returning an array of strings" do
      req_data, rep_data = [ "1", "2" ], [ "2", "3" ]

      APIHelper.with_pair_sockets(ZMQ::REQ, ZMQ::REP) do |req, rep|
        req.bind MULTIPART_ENDPOINT
        APIHelper.connect_to_inproc rep, MULTIPART_ENDPOINT

        req.send_strings(req_data)
        rep.receive_strings.should eq(req_data)

        rep.send_strings(rep_data)
        req.receive_strings.should eq(rep_data)
      end
    end
  end

  context "with identity" do
    it "delivers between REQ and REP returning an array of strings with an empty string as the envelope delimiter" do
      APIHelper.with_pair_sockets(ZMQ::REQ, ZMQ::XREP) do |req, rep|
        req.identity = "TestReq"
        req_data, rep_data = "hello", [ req.identity, "", "ok" ]

        req.bind MULTIPART_ENDPOINT
        APIHelper.connect_to_inproc rep, MULTIPART_ENDPOINT

        req.send_string(req_data)
        rep.receive_messages.map(&.to_s).should eq([ req.identity, "", "hello" ])

        rep.send_strings(rep_data)
        req.receive_string.should eq(rep_data.last)
      end
    end

    it "delivers between REQ and REP returning an array of of messages with an empty string as the envelope delimiter" do
      APIHelper.with_pair_sockets(ZMQ::REQ, ZMQ::XREP) do |req, rep|
        req.identity = "TestReq"
        req_data, rep_data = "hello", [ req.identity, "", "ok" ]

        req.bind MULTIPART_ENDPOINT
        APIHelper.connect_to_inproc rep, MULTIPART_ENDPOINT

        req.send_string(req_data)
        rep.receive_messages.map(&.to_s).should eq([ req.identity, "", "hello" ])

        rep.send_strings(rep_data)
        req.receive_message.to_s.should eq(rep_data.last)
      end
    end
  end
end
