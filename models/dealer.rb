require 'celluloid/current'
require 'stock_knight'

class Dealer
  include Celluloid

  attr_reader :client, :stock, :profit

  def initialize(profit)
    @client = StockKnight::Client.new(ENV['APIKEY'])

    @client.configure do |config|
      config.account      = ENV['ACCOUNT']
      config.venue        = ENV['VENUE']
      config.debug_output = false #  Log request and response info
    end

    @stock = ENV['STOCK']

    @profit = profit
  end

  def deal(bid:, ask:)
    return if bid == 0

    amount = buy_ioc(price: bid, qty: 60)
    return 0 if amount.zero?

    base = bid*amount
    sell_ioc(price: ask, qty: amount, base: base)
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

  def buy_limit(price:, qty:)
    type = :limit

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

    puts "#{id} --> bought #{amount} at #{price}"

    return amount
  end

  def buy_ioc(price:, qty:)
    type = :immediate_or_cancel

    puts "#{id} --> buy #{qty} at #{price}"
    resp = client.buy(stock, price: price, qty: qty, type: type)
    amount = resp[:totalFilled]

    if amount == 0
      puts "#{id} --> amount 0"
      return 0
    else
      puts "#{id} --> bought #{amount} at #{price}"
      return amount
    end
  end

  def sell_limit(price:, qty:, base:)
    type = :limit

    sum = 0
    loop do
      puts "#{id} --> sell #{qty} at #{price}"

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

  def sell_ioc(price:, qty:, base:)
    type = :immediate_or_cancel

    sum = 0
    loop do
      puts "#{id} --> sell #{qty} at #{price}"

      resp = client.sell(stock, price: price, qty: qty, type: type)
      amount = resp[:totalFilled].to_i

      if amount == 0
        price -= 50
        next
      end

      puts "#{id} --> sold #{amount} at #{price}"

      sum += amount*price
      qty -= amount
      price -= 50

      break if qty == 0
    end

    value = sum - base
    profit.increment_by(value)

    value = "+#{value}" if value >= 0
    puts "#{id} --> profit: #{profit.value} (#{value})"
  end

end

