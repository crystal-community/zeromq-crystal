require "../src/zeromq"

NMB_OF_CLIENTS = 1
NMB_OF_WORKERS = 1
SYNCKER = Channel(Nil).new
FRONT_LINK = "ipc://frontend.ipc"

def client(id)
  puts "I: Client #{id} started..."

  ZMQ::Context.create ZMQ::DEALER do |_, (client)|
    client.identity = "client-#{id}" # % rand(0x10000)
    client.connect(FRONT_LINK) || puts("Client: #{id} was not able to connect to frontend!")

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
      puts "\nClient #{client.identity} sent #{request_number}"
      SYNCKER.send nil  # Fiber.yield
    end
  end
end

def worker(context, id)
  puts "I: Worker #{id} started"

  context.socket ZMQ::DEALER do |worker|
    worker.identity = "worker-#{id}"
    worker.connect("inproc://backend") || raise("Worker: #{id} was not able to connect!")

    loop do
      messages = worker.receive_strings(ZMQ::DONTWAIT)
      if messages.empty?
         SYNCKER.send nil
         sleep 0.5
         next
      end

      puts "\nWorker #{id} received: messages.join(", ")"
      rand(4).times do |it|
        sleep it
        # break if
        worker.send_strings(messages, ZMQ::DONTWAIT)
      end

      SYNCKER.send nil
    end
  end
end

def server
  ZMQ::Context.create ZMQ::ROUTER, ZMQ::DEALER do |context, (frontend, backend)|
    NMB_OF_WORKERS.times do |it|
      spawn worker(context, it) # Fiber.yield
    end

    # Fiber.yield

    spawn do
      frontend.bind(FRONT_LINK) || raise("Server was not able to bind to forntend!")
      backend.bind("inproc://backend") || raise("Server was not able to bind to backend!")

      puts "Device started..."
      ZMQ::Device.new frontend, backend # ZMQ::QUEUE,
      SYNCKER.send nil
    end

    loop do
      # Fiber.yield
      SYNCKER.receive
    end
  end
 end

NMB_OF_CLIENTS.times do |it|
  spawn client(it)
  # SYNCKER.receive
end

server
