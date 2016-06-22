require "../src/zeromq"

context = ZMQ::Context.new
uri = "inproc://example"

sink = context.socket(ZMQ::ROUTER)
sink.bind(uri)

# 0MQ will set the identity here
anonymous = context.socket(ZMQ::DEALER)
anonymous.connect(uri)
anon_message = ZMQ::Message.new("ROUTER uses a generated 5 byte identity")
anonymous.send_message(anon_message)

msgs = sink.receive_strings
puts msgs.join(", ")
# Set the identity ourselves
identified = context.socket(ZMQ::DEALER)
identified.set_socket_option(ZMQ::IDENTITY, "PEER2")
identified.connect(uri)
identified_message = ZMQ::Message.new("Router uses socket identity")
identified.send_message(identified_message)

msgs = sink.receive_strings
puts msgs.join(", ")
