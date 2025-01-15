#!/usr/bin/env -S falcon serve --bind http://localhost:7070 --count 1 -c

require 'async/websocket/adapters/rack'
require 'async/redis'

class ChatServer
  def initialize(app, endpoint: Async::Redis.local_endpoint)
    @app = app
    @endpoint = endpoint

    @client = Async::Redis::Client.new(endpoint)
  end

  def call(env)
    Async::WebSocket::Adapters::Rack.open(env, protocols: ['ws']) do |connection|
      loop do
        channel = connection.read.to_str
  
        subscribe(channel) do |context|
          Console.info(connection, "Subscribed", channel: channel)
  
          loop do
            event = context.listen

            Protocol::WebSocket::TextMessage.generate(event).send(connection)

            connection.flush
          end
        end
      end
    end or @app.call(env)
  end

  private

  def subscribe(channel, &block)
    @client.subscribe(channel, &block)
  end
end

use ChatServer

use Rack::Static, urls: ["/"], root: "public", index: "index.html"

run do |env|
  [404, {}, []]
end
