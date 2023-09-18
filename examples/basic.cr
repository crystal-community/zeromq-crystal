require "../src/zeromq"

# Simple server
context = ZMQ::Context.new
server = context.socket(ZMQ::REP)
server.bind("tcp://127.0.0.1:5555")

# Simple client
context = ZMQ::Context.new
client = context.socket(ZMQ::REQ)
client.connect("tcp://127.0.0.1:5555")

client.send_string("Fetch")

puts server.receive_string
server.send_string("Got it")

puts client.receive_string
