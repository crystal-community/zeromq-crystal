require "../src/zeromq"

context = ZMQ::Context.new
num_requests = 10_000
link = "tcp://127.0.0.1:5555"

close = Channel(Nil).new

start = Time.monotonic

spawn do
  puts "Start server"
  responder = context.socket(ZMQ::REP)
  responder.bind(link)

  num_requests.times do
    Fiber.yield
    message = responder.receive_message
    responder.send_message(message)
  end

  responder.close
end

spawn do
  puts "Start client"
  requester = context.socket(ZMQ::REQ)

  requester.connect(link)

  num_requests.times do |index|
    requester.send_string("Hello")
    Fiber.yield
    requester.receive_string
  end

  requester.close
  close.send(nil)
end
close.receive
context.terminate

seconds = (Time.monotonic - start).total_seconds
puts "Messages per second: #{(num_requests * 2) / seconds.to_f}"
puts "Total seconds: #{seconds}"
