require 'celluloid/current'
require 'stock_knight'

class Dealer
  include Celluloid

  attr_reader :client, :stock
  attr_accessor :share

  MAX = 200
  RECENT = 5

  def initialize
    @client = StockKnight::Client.new(ENV['APIKEY'])

    @client.configure do |config|
      config.account      = ENV['ACCOUNT']
      config.venue        = ENV['VENUE']
      config.debug_output = false #  Log request and response info
    end

    @stock = ENV['STOCK']

    @share = 0
  end

  def deal
    puts "--> Start dealing"
    begin
      profit = 0
      round = 0

      loop do
        next if last_quote.nil?

        bid = last_ask + 200
        ask = bid + 200

        filled = 0
        puts "##{id}-#{round} --> buy"
        order = client.buy(stock, price: bid, qty: 200, type: :limit)[:id]

        puts "##{id}-#{round} --> sleep"
        sleep(3)
        resp = client.query(stock, order: order)
        bought = resp[:totalFilled].to_i
        p resp

        puts "##{id}-#{round} --> bought: #{bought}"
        if bought == 0
          resp = client.cancel(stock, order: order)
          bought = resp[:totalFilled].to_i

          if bought == 0
            next
          end
        end

        filled += bought
        puts "##{id}-#{round} --> bought #{bought} at #{bid}, filled: #{filled}"
        profit -= bought * bid

        loop do
          ask -= 10
          order = client.sell(stock, price: ask, qty: filled, type: :limit)[:id]
          sleep(2)
          resp = client.query(stock, order: order)
          sold = resp[:totalFilled].to_i

          if sold == 0
            resp = client.cancel(stock, order: order)
            sold = resp[:totalFilled].to_i

            if sold == 0
              next
            end
          end

          filled -= sold
          puts "##{id}-#{round} --> Sold: #{sold} at #{ask}, filled: #{filled}"
          profit += sold * ask

          break if filled == 0
        end

        puts "##{id}-#{round} --> profit: #{profit}"
        round += 1
      end
    rescue => e
      puts e.message
      retry
    end
  end

  def id
    self.object_id
  end

  def collection
    Quote.order_by(lastTrade: :desc)
  end

  def last_quote
    collection.first
  end

  def last_bid
    last_quote.bid
  end

  def last_ask
    last_quote.bid
  end

end

