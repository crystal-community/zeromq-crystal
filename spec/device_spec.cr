require "./spec_helper"

FRONT_ENDPOINT = "inproc://device_front_test"
BACK_ENDPOINT  = "inproc://device_back_test"
CHANNEL        = Channel(String).new

def create_streamer
  ZMQ::Context.create(ZMQ::PUSH, ZMQ::PULL) do |ctx, (front, back)|
    back.bind(BACK_ENDPOINT) || puts("Not able to bind to #{BACK_ENDPOINT}")
    front.bind(FRONT_ENDPOINT) || puts("Not able to bind to #{FRONT_ENDPOINT}")
    CHANNEL.send "ping"
    ZMQ::Device.new(back, front)
  end
  puts "\n I: device exited"
end

def create_raw_streamer
  ZMQ::Context.create(ZMQ::ROUTER, ZMQ::DEALER) do |ctx, (frontend, backend)|
    frontend.bind(FRONT_ENDPOINT)
    backend.bind(BACK_ENDPOINT)

    poller = APIHelper::HELPER_POLLER # ZMQ::Poller.new
    poller.register(frontend, ZMQ::POLLIN)
    poller.register(backend, ZMQ::POLLIN)
    CHANNEL.send true

    loop do
      Fiber.yield
      puts "\n I: Poller start poll for: 100 ms." if poller.poll(-1) > 0
      poller.readables.each do |socket|
        if socket === frontend
          messages = socket.receive_strings
          puts "\n I: Poller front received: #{messages.join(", ")}"
          backend.send_strings(messages)
        elsif socket === backend
          messages = socket.receive_strings
          puts "\n I: Poller back received: #{messages.join(", ")}"
          frontend.send_strings(messages)
        else
          puts "\n I: Unknown socket"
        end
      end
      CHANNEL.send true # Fiber.yield
    end
  end
end

describe ZMQ::Device do
  # pending because it hangs
  pending "is able to send messages through the device" do
    spawn create_streamer # wait_for_device
    CHANNEL.receive

    spawn do
      ZMQ::Context.create(ZMQ::PUSH, ZMQ::PULL) do |ctx, (pusher, puller)|
        APIHelper.connect_to_inproc(pusher, BACK_ENDPOINT)
        APIHelper.connect_to_inproc(puller, FRONT_ENDPOINT)

        APIHelper.poll_it_for_read(puller) do
          pusher.send_string("hello")
          puts "Send hello..."
        end

        CHANNEL.send(puller.receive_string(ZMQ::DONTWAIT)) # .should eq("hello")
      end

      CHANNEL.receive.should eq("hello")
    end
  end
end
