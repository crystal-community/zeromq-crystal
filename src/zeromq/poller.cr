class ZMQ::Poller
  def initialize
    @poll_items = [] of {Socket(Message), Int32}
    @readables = [] of Socket(Message)
    @writables = [] of Socket(Message)
  end

  def poll(timeout)
    items = Pointer(LibZMQ::PollItem).malloc(@poll_items.size) do |i|
      socket, type = @poll_items[i]
      item = LibZMQ::PollItem.new
      item.socket = socket.socket
      item.events = type
      item
    end

    items_triggered = LibZMQ.poll(items, @poll_items.size, timeout)

    if Util.resultcode_ok?(items_triggered)
      @readables.clear
      @writables.clear

      @poll_items.each_with_index do |poll_item, index|
        @readables << poll_item[0] if items[index].revents & POLLIN > 0
        @writables << poll_item[0] if items[index].revents & POLLOUT > 0
      end
      items_triggered
    else
      0
    end
  end

  def poll_nonblock
    loop do
      items = poll(0)
      yield readables, writables if items > 0
      Fiber.yield
    end
  end

  def readables
    @readables
  end

  def writables
    @writables
  end

  def register(socket, type = POLLIN | POLLOUT)
    @poll_items << {socket, type}
  end

  def register_readable(socket)
    register(socket, POLLIN)
  end

  def register_writable(socket)
    register(socket, POLLOUT)
  end
end
