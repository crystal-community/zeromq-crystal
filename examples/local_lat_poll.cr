require "../src/zeromq"

if ARGV.size < 2
  puts "usage: crystal local_lat_poll.cr <message-size> <roundtrip-count>"
  exit
end

link = "tcp://127.0.0.1:5555"
message_size = ARGV[0].to_i
roundtrip_count = ARGV[1].to_i

begin
  ctx = ZMQ::Context.new
  s1 = ctx.socket(ZMQ::REQ)
  s2 = ctx.socket(ZMQ::REP)
rescue e : ZMQ::ContextError
  STDERR.puts "Failed to allocate context or socket!"
  raise e
end

s1.set_socket_option(ZMQ::LINGER, 100)
s2.set_socket_option(ZMQ::LINGER, 100)

s2.bind(link)     || puts "binding failed #{link}"
s1.connect(link)  || puts "connect failed"

poller = ZMQ::Poller.new
poller.register_readable(s2)
poller.register_readable(s1)

start_time = Time.now

# kick it off
message = ZMQ::Message.new("a" * message_size)
s1.send_message(message, ZMQ::DONTWAIT)

i = roundtrip_count

until i == 0
  i -= 1

  poller.poll(-1)

  poller.readables.each do |socket|
    received_message = socket.receive_message(ZMQ::DONTWAIT)
    socket.send_message(received_message, ZMQ::DONTWAIT)
  end
end

span = (Time.now - start_time)
latency = span.ticks.to_f / roundtrip_count / 2.0

puts "mean latency: %.3f [us]" % latency
puts "messages per second: %.3f " % (roundtrip_count / span.total_seconds)
puts "received all messages in %.3f ms" % (span.total_milliseconds)

s1.close
s2.close

ctx.terminate
