require 'celluloid/current'
require 'stock_knight'

class Dealer
  include Celluloid

  attr_reader :client, :stock

  def initialize
    @client = StockKnight::Client.new(ENV['APIKEY'])

    @client.configure do |config|
      config.account      = ENV['ACCOUNT']
      config.venue        = ENV['VENUE']
      config.debug_output = false #  Log request and response info
    end

    @stock = ENV['STOCK']
  end

  def buy_low
    price = buy_in_price
    return if price == 0

    price += 10
    amount = buy(price: price, qty: 60, type: :limit)
    if amount > 0
      sell(price: price+300, qty: amount, type: :limit, base: price*amount)
    else
      0
    end
  end

  def deal
    return if last_quote.nil?
    return if last_bid == 0

    price = last_bid + 10
    amount = buy(price: price, qty: 200, type: :limit)
    if amount > 0
      sell(price: price+200, qty: amount, type: :limit, base: price*amount)
    else
      0
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
    (last_quote.bid * 100).to_i
  end

  def last_ask
    (last_quote.ask * 100).to_i
  end

  def buy_in_price
    prices = collection.limit(3).pluck(:bid).reject(&:zero?)
    sum = prices.sum
    return 0 if sum.zero?

    (sum * 100.0 / prices.count).to_i
  end

  def buy(price:, qty:, type:)
    puts "#{id} --> buy #{qty} at #{price}"
    order = client.buy(stock, price: price, qty: qty, type: type)[:id]

    # puts "#{id} --> sleep"
    # sleep( rand(1) )
    resp = client.query(stock, order: order)
    amount = resp[:totalFilled].to_i

    if amount == 0
      resp = client.cancel(stock, order: order)
      amount = resp[:totalFilled].to_i

      if amount.zero?
        puts "#{id} --> amount 0"
        return 0
      end
    end

    # orders << Order.new(:buy, amount, price)
    puts "#{id} --> bought #{amount} at #{price}"

    return amount
  end

  def sell(price:, qty:, type:, base:)
    puts "#{id} --> sell #{qty} at #{price}"

    sum = 0
    loop do
      order = client.sell(stock, price: price, qty: qty, type: type)[:id]

      # sleep( rand(1) )
      resp = client.query(stock, order: order)
      amount = resp[:totalFilled].to_i

      if amount == 0
        resp = client.cancel(stock, order: order)
        amount = resp[:totalFilled].to_i

        if amount.zero?
          price -= 20
          next
        end
      end

      # orders << Order.new(:sell, amount, price)
      puts "#{id} --> sold #{amount} at #{price}"

      sum += amount*price

      qty -= amount
      price -= 20
      break if qty == 0
    end

    puts "#{id} --> profit: #{sum-base}"
    sum - base
  end

  def orders
    Thread.current[:orders] ||= []
    Thread.current[:orders]
  end

  Order = Struct.new(:op, :amount, :price) do
    def profit
      if op == :buy
        0 - (amount * price)
      else
        amount * price
      end
    end
  end

end

