#!/usr/bin/env -S falcon serve --bind http://localhost:7070 --count 1 -c

require 'async/websocket/adapters/rack'
require 'async/redis'

# key: channel name
# value: An array of connections for the channel
$connections = Hash.new { |h, k| h[k] = [] }

run lambda {|env|
  client = Sync do
    endpoint = Async::Redis.local_endpoint
    Async::Redis::Client.new(endpoint)
  end

  Async::WebSocket::Adapters::Rack.open(env, protocols: ['ws']) do |connection|
    loop do
      channel = connection.read.to_str
      puts "channel: #{channel}"

      $connections[channel] << connection

      client.subscribe(channel) do |context|
        puts "subscribed to #{channel}"

        loop do
          event = context.listen
          puts "event: #{event}"

          $connections[channel].each do |conn|
            conn.write("message: #{event[2]}")
            conn.flush
          end
        end
      end
    end
  ensure
    $connections.delete(connection)
  end
}
