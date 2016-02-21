$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)
require 'stock_knight'

client = StockKnight::Client.new(ENV['APIKEY'])
gm     = StockKnight::GameMaster.new(ENV['APIKEY'])

stock = nil
instance_id = nil

5.times do
  resp = gm.start(:first_steps)

  unless resp[:ok]
    puts resp[:error]
    next
  end

  client.configure do |config|
    config.account = resp[:account]
    config.venue   = resp[:venues].first
  end

  stock       = resp[:tickers].first
  instance_id = resp[:instanceId]
end

client.buy(stock, price: 0, qty: 100, type: :market)
