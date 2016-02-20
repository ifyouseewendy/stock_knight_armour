require 'celluloid/current'
require 'stock_knight'

class Dealer
  include Celluloid

  SHARE = 120

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
    @self_profit = Profit.new
    @transaction_count = Profit.new
    @index  = 0
  end

  # def deal_buy_low_first(index:)
  #   price = Quote.buy_in_price
  #   return if price.zero?
  #
  #   @index = index
  #
  #   bid = ( price * 100 * 0.7 ).to_i
  #
  #   amount, fill_price = buy_limit(price: bid, qty: SHARE)
  #   return 0 if amount.zero?
  #
  #   base = amount * fill_price
  #   ask_price = ( price * 100 * 0.95 ).to_i
  #
  #   sell_limit(price: ask_price, qty: amount, base: base)
  # end
  #
  # def deal_sell_high_first(index:)
  #   price = Quote.buy_in_price
  #   return if price.zero?
  #
  #   @index = index
  #
  #   ask = ( price * 100 * 1.3 ).to_i
  #
  #   amount, fill_price = sell_limit(price: ask, qty: SHARE)
  #   return 0 if amount.zero?
  #
  #   base = amount * fill_price
  #   bid_price = ( price * 100 * 1.05 ).to_i
  #
  #   buy_limit(price: bid_price, qty: amount, base: base)
  # end

  def deal(index:)
    price = Quote.buy_in_price
    return if price.zero?

    @index = index

    bid_rate, bid_share = 1, (0.04/Manager::DEALER_COUNT)
    bid_rate -= index * bid_share
    bid = ( price * 100 * bid_rate ).to_i

    return if bid == 0

    amount, fill_price = buy_limit(price: bid, qty: SHARE)
    return 0 if amount.zero?

    base = amount * fill_price
    ask_price = [fill_price+200, (bid*0.95).to_i].max

    sell_limit_block(price: ask_price, qty: amount, base: base)
  end

  def id
    "##{@index}"
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
    resp = client.cancel(stock, order: order)

    fills = resp[:fills]
    return 0 if fills.nil?

    fill_qty  = fills.map{|ha| ha['qty'].to_i}.sum
    fill_sum = fills.map{|ha| ha['price'].to_i * ha['qty'].to_i}.sum

    if fill_qty.zero?
      puts "#{id} --> amount 0"
      return 0
    else
      fill_price = (fill_sum/fill_qty.to_f).to_i
      puts "#{id} --> bought #{fill_qty} at #{fill_price}"
      return fill_qty, fill_price
    end
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
      fill_price = resp[:fills][0]['price']
      puts "#{id} --> bought #{amount} at #{price}"
      return amount, fill_price
    end
  end

  def buy_limit_block(price:, qty:, base:)
    type = :limit

    sum = 0
    down_price = [100]
    pos = 0
    loop do
      puts "#{id} --> buy #{qty} at #{price}"

      order = client.buy(stock, price: price, qty: qty, type: type)[:id]
      resp = client.cancel(stock, order: order)

      fills = resp[:fills]
      next if fills.nil?

      fill_qty  = fills.map{|ha| ha['qty'].to_i}.sum
      fill_sum = fills.map{|ha| ha['price'].to_i * ha['qty'].to_i}.sum

      sum += fill_sum

      if qty == fill_qty
        puts "#{id} --> bought #{fill_qty} at #{price}"
        break
      else
        puts "#{id} --> bought #{fill_qty}"
        qty -= fill_qty
        price += (down_price[pos] || 100)
        pos += 1
      end
    end

    value = base - sum
    profit.increment_by(value)
    @self_profit.increment_by(value)
    @transaction_count.increment_by(1)

    value = "+#{value}" if value >= 0
    puts "#{id} --> profit: #{profit.value} (#{value}, self_profit: #{@self_profit.value}, transaction_count: #{@transaction_count.value})"
  end

  def sell_limit(price:, qty:)
    type = :limit

    puts "#{id} --> sell #{qty} at #{price}"
    order = client.sell(stock, price: price, qty: qty, type: type)[:id]
    resp = client.cancel(stock, order: order)

    fills = resp[:fills]
    return 0 if fills.nil?

    fill_qty  = fills.map{|ha| ha['qty'].to_i}.sum
    fill_sum = fills.map{|ha| ha['price'].to_i * ha['qty'].to_i}.sum

    if fill_qty.zero?
      puts "#{id} --> amount 0"
      return 0
    else
      fill_price = (fill_sum/fill_qty.to_f).to_i
      puts "#{id} --> sold #{fill_qty} at #{fill_price}"
      return fill_qty, fill_price
    end
  end

  def sell_limit_block(price:, qty:, base:)
    type = :limit

    sum = 0
    down_price = [100]
    pos = 0
    loop do
      puts "#{id} --> sell #{qty} at #{price}"

      order = client.sell(stock, price: price, qty: qty, type: type)[:id]
      # sleep(2)
      resp = client.cancel(stock, order: order)

      fills = resp[:fills]
      next if fills.nil?

      fill_qty  = fills.map{|ha| ha['qty'].to_i}.sum
      fill_sum = fills.map{|ha| ha['price'].to_i * ha['qty'].to_i}.sum

      sum += fill_sum

      if qty == fill_qty
        puts "#{id} --> sold #{fill_qty} at #{price}"
        break
      else
        puts "#{id} --> sold #{fill_qty}"
        qty -= fill_qty
        price -= (down_price[pos] || 100)
        pos += 1
      end
    end

    value = sum - base
    profit.increment_by(value)
    @self_profit.increment_by(value)
    @transaction_count.increment_by(1)

    value = "+#{value}" if value >= 0
    puts "#{id} --> profit: #{profit.value} (#{value}, self_profit: #{@self_profit.value}, transaction_count: #{@transaction_count.value})"
  end

  def sell_ioc(price:, qty:, base:)
    type = :immediate_or_cancel

    sum = 0
    loop do
      puts "#{id} --> sell #{qty} at #{price}"

      resp = client.sell(stock, price: price, qty: qty, type: type)
      amount = resp[:totalFilled].to_i

      if amount == 0
        price -= 40
        next
      end

      puts "#{id} --> sold #{amount} at #{price}"

      fill_price = resp[:fills][0]['price'].to_i
      sum += amount*fill_price
      qty -= amount
      price -= 40

      break if qty == 0
    end

    value = sum - base
    profit.increment_by(value)

    value = "+#{value}" if value >= 0
    puts "#{id} --> profit: #{profit.value} (#{value})"
  end

end

