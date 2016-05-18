require "../src/zeromq"

if ARGV.size < 3
  puts "usage: crystal local_lat_poll.cr <connect-to> <message-size> <roundtrip-count>"
  exit
end

link = ARGV[0]
message_size = ARGV[1].to_i
roundtrip_count = ARGV[2].to_i

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

s2.bind(link) || puts "binding failed #{link}"
s1.connect(link) || puts "connect failed"

poller = ZMQ::Poller.new
poller.register_readable(s2)
poller.register_readable(s1)

start_time = Time.now

# kick it off
message = ZMQ::Message.new("a" * message_size)
p s1.send_message(message, ZMQ::DONTWAIT)

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
puts "received all messages in %.3f ms" % (span.total_milliseconds)

p s1.close
p s2.close

ctx.terminate
