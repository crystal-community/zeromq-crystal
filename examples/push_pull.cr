require "../src/zeromq"

context = ZMQ::Context.new
num_requests = 10_000
link = "tcp://127.0.0.1:5555"

close = Channel(Nil).new

start = Time.now

spawn do
  puts "Start server"
  responder = context.socket(ZMQ::PULL)
  responder.set_socket_option(ZMQ::LINGER, 100000)
  responder.bind(link)

  Fiber.yield

  num_requests.times do
    responder.receive_string
  end

  responder.close

  close.send(nil)
end

spawn do
  puts "Start client"
  requester = context.socket(ZMQ::PUSH)

  requester.connect(link)

  num_requests.times do
    requester.send_string("Hello")
  end
  requester.close
end

close.receive
context.terminate

seconds = (Time.now - start).total_seconds
puts "Messages per second: %.3f" % (num_requests / seconds.to_f)
puts "Total seconds: #{seconds}"
