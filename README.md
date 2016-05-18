# zeromq

Bindings for ZeroMQ (http://zero.mq)
Ported from (https://github.com/chuckremes/ffi-rzmq-core) Thank you @chuckremes

## Installation

Add this to your application's `shard.yml`:

```yaml
dependencies:
  zeromq:
    github: [benoist]/zeromq-crystal
```


## Usage


```crystal
require "zeromq"
```

```crystal

# Simple server
context = ZMQ::Context.new
server = context.socket(ZMQ::REP)
server.bind("tcp://127.0.0.1:5555")

loop do
    puts server.receive_string
    server.send_string("Got it")
end

# Simple client
context = ZMQ::Context.new
client = context.socket(ZMQ::REP)
client.bind("tcp://127.0.0.1:5555")

client.send_string("Fetch")
puts client.receive_string
```

## TODO

- [ ] Add tests
- [ ] Add more examples

## Contributing

1. Fork it ( https://github.com/benoist/zeromq-crystal/fork )
2. Create your feature branch (git checkout -b my-new-feature)
3. Commit your changes (git commit -am 'Add some feature')
4. Push to the branch (git push origin my-new-feature)
5. Create a new Pull Request

## Contributors

- [Benoist](https://github.com/benoist) Benoist Claassen - creator, maintainer
