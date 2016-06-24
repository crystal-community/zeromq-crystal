require "../src/zeromq"

NMB_OF_CLIENTS = 3
NMB_OF_WORKERS = 5
SYNCKER = Channel(Nil).new

def client(id)
  ZMQ::Context.create ZMQ::DEALER do |_, (client)|
    client.identity = "client-#{id}" # % rand(0x10000)
    client.connect("ipc://frontend.ipc") || puts("Client: #{id} was not able to connect to frontend!")

    poller = ZMQ::Poller.new
    poller.register_readable(client)

    request_number = 0
    loop do
      10.times do |tick|
        if poller.poll(1) > 0
          message = client.receive_string(ZMQ::DONTWAIT)
          puts "\nClient: #{client.identity} get message: #{message}" unless message.empty?
        end
      end

      client.send_string "Req ##{request_number += 1}", ZMQ::DONTWAIT
      # puts "\nClient #{client.identity} sent #{request_number}"
      SYNCKER.send nil  # Fiber.yield
    end
  end
end

def worker(context, id)
  context.socket ZMQ::DEALER do |worker|
    worker.identity = "worker-#{id}"
    worker.connect("inproc://backend") || raise("Worker: #{id} was not able to connect!")

    loop do
      messages = worker.receive_strings(ZMQ::DONTWAIT)
      unless messages.empty?
        rand(4).times do |it|
          sleep it
          # break if
          worker.send_strings(messages, ZMQ::DONTWAIT)
        end
      end

      SYNCKER.send nil
    end
  end
end

def server
  ZMQ::Context.create ZMQ::ROUTER, ZMQ::DEALER do |context, (frontend, backend)|
    NMB_OF_WORKERS.times do |it|
      spawn worker(context, it)
      puts "I: Worker #{it} started" # Fiber.yield
    end

    spawn do
      frontend.bind("ipc://frontend.ipc") || raise("Server was not able to bind to forntend!")
      backend.bind("inproc://backend")    || raise("Server was not able to bind to backend!")

      ZMQ::Device.new frontend, backend # ZMQ::QUEUE,
    end
  end
 end

NMB_OF_CLIENTS.times do |it|
  spawn client(it)
  puts "I: Client #{it} started..."
end

server
loop { SYNCKER.receive }
