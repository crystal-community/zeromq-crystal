require "../src/zeromq"
# NOTE: This is ruby translation into Crystal of Peering1 example from 0mq book

module Utils
  extend self

  def with_thread_form_args(args)
    form_args(args).each do |it|
      spawn { yield it }
    end
  end

  alias Complex   = Tuple(String, Array(String))
  alias Arguments = Array(Complex) | Array(String)

  def form_args(args : Array(String)) : Arguments
    i, res = args.size, [] of Complex
    while i > 0
      res << { it = args.shift, args.dup }
      args << it
      i -= 1
    end

    res
  end
end

module State
  def self.main(args : Array(String))
    Utils.form_args(args).each do |args_tuple|
      spawn do
        begin
          Broker.new(*args_tuple).run
        rescue ex : ArgumentError
          puts "#{ex.message} usage: ruby peering1.rb broker_name [peer_name …]"
        end
      end
    end
  end

  class Broker
    LINGER_TIMEOUT = 1
    alias Socket   = ZMQ::Socket # (ZMQ::Message)

    @state_backend : Socket
    @state_frontend : Socket

    def initialize(@name : String, @peers : Array(String))
      raise ArgumentError.new("A broker require's a name") unless @name
      raise ArgumentError.new("A broker require's peers")  unless @peers.any?

      @context        = ZMQ::Context.new
      @state_backend  = @context.socket ZMQ::PUB
      @state_frontend = @context.socket ZMQ::SUB
      setup_state

      puts "Starting broker: #{@name}"
    end

    def run
      peer_name, available = "", ""
      poller = ZMQ::Poller.new
      poller.register_readable @state_frontend

      until poller.poll(LINGER_TIMEOUT) == -1
        if poller.readables.any?
          peer_name = @state_frontend.receive_string(ZMQ::DONTWAIT) # peer_name
          available = @state_frontend.receive_string(ZMQ::DONTWAIT) # available

          puts "#{peer_name} - #{available} workers free"
        else
          Fiber.yield
          msg = rand(10).to_s
          @state_backend.send_strings [@name, msg]

          puts "Report own status: #{@name}, #{msg}"
        end
      end

      @state_frontend.close
      @state_backend.close
      @context.terminate
    end

    private def socket_name(name : String)
      "ipc://#{name}-state.ipc"
    end

    private def setup_state
      [@state_backend, @state_frontend].each { |sock| sock.set_socket_option(ZMQ::LINGER, LINGER_TIMEOUT) }
      @state_backend.bind(socket_name(@name)) || puts("binding failed #{socket_name(@name)}")
      @peers.each do |peer|
        puts "I: connecting to state backend at #{peer}"
        @state_frontend.connect(socket_name(peer)) ||  puts("binding failed socket_name(peer)")
        @state_frontend.set_socket_option( ZMQ::SUBSCRIBE, peer)
      end
    end
  end
end

if ARGV.size < 2
  puts "usage: crystal peering1.cr -- name1 name2 ... nameN"
  exit(1)
end

State.main(ARGV)
# State::Broker.new(ARGV.shift, ARGV).run
sleep # Process.wait
