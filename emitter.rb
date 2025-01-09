require 'async'
require 'async/redis'

channel, message = ARGV

Async do
  endpoint = Async::Redis.local_endpoint
  client = Async::Redis::Client.new(endpoint)
  client.publish(channel, message)
end
