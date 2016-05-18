require "../src/zeromq"
link = "tcp://127.0.0.1:5555"

begin
  ctx = ZMQ::Context.new
  s1 = ctx.socket(ZMQ::PUB)
  s2 = ctx.socket(ZMQ::SUB)
  s3 = ctx.socket(ZMQ::SUB)
  s4 = ctx.socket(ZMQ::SUB)
rescue e : ZMQ::ContextError
  STDERR.puts "Failed to allocate context or socket!"
  raise e
end

s1.set_socket_option(ZMQ::LINGER, 100)
s2.set_socket_option(ZMQ::SUBSCRIBE, "") # receive all
s3.set_socket_option(ZMQ::SUBSCRIBE, "animals") # receive any starting with this string
s4.set_socket_option(ZMQ::SUBSCRIBE, "animals.dog")

s1.bind(link)
s2.connect(link)
s3.connect(link)
s4.connect(link)

sleep 1

topic = "animals.dog"
payload = "Animal crackers!"

s1.identity = "publisher-A"
puts "sending"
# use the new multi-part messaging support to
# automatically separate the topic from the body
s1.send_string(topic, ZMQ::SNDMORE)
s1.send_string(payload, ZMQ::SNDMORE)
s1.send_string(s1.identity)

topic = s2.receive_string

body = s2.receive_string if s2.more_parts?

identity = s2.receive_string if s2.more_parts?
puts "s2 received topic [#{topic}], body [#{body}], identity [#{identity}]"



topic = s3.receive_string

body = s3.receive_string if s3.more_parts?
puts "s3 received topic [#{topic}], body [#{body}]"

topic = s4.receive_string

body = s4.receive_string if s4.more_parts?
puts "s4 received topic [#{topic}], body [#{body}]"

[s1, s2, s3, s4].each do |socket|
  socket.close
end

ctx.terminate
