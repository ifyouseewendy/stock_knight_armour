require 'celluloid/current'
require 'stock_knight'

class Dealer
  include Celluloid

  attr_reader :client, :stock, :profit, :share, :index

  def initialize(index, profit, share)
    initialize_client

    @index  = index
    @profit = profit
    @share  = share
    @self_profit = DbCounter.new("self_profit_#{index}")
    @transaction_count = DbCounter.new("transaction_count_#{index}")
  end

  def initialize_client
    @client = StockKnight::Client.new(ENV['APIKEY'])

    @client.configure do |config|
      config.account      = ENV['ACCOUNT']
      config.venue        = ENV['VENUE']
      config.debug_output = false #  Log request and response info
    end

    @stock = ENV['STOCK']
  end

  def valid_share_value
    share_now = share.value
    if share_now.abs > (1000 - Manager::SHARE - 50)
      puts "#{id} --> sell skip, current share: #{share_now}"
      false
    else
      true
    end
  end

  def deal_buy_low_first
    return unless valid_share_value

    price = Quote.good_price(based_on: :ask)
    return if price.zero?

    bid = ( price * 100 * 0.7 ).to_i

    amount, fill_price = buy(type: :limit, price: bid, qty: Manager::SHARE)
    return 0 if amount.zero?

    base = amount * fill_price
    ask_price = ( price * 100 * 0.95 ).to_i

    sell_block(type: :limit, price: ask_price, qty: amount, base: base)
  end

  def deal_sell_high_first
    return unless valid_share_value

    price = Quote.good_price(based_on: :bid)
    return if price.zero?

    ask = ( price * 100 * 1.3 ).to_i

    amount, fill_price = sell(type: :limit, price: ask, qty: Manager::SHARE)
    return 0 if amount.zero?

    base = amount * fill_price
    bid_price = ( price * 100 * 1.05 ).to_i

    buy_block(type: :limit, price: bid_price, qty: amount, base: base)
  end

  def deal_buy_first
    return unless valid_share_value

    price = Quote.good_price(based_on: :ask)
    return if price.zero?

    bid_rate, bid_share = 1, (0.04/Manager::DEALER)
    bid_rate -= index * bid_share
    bid = ( price * 100 * bid_rate ).to_i

    return if bid == 0

    amount, fill_price = buy(type: :limit, price: bid, qty: Manager::SHARE)
    return 0 if amount.zero?

    base = amount * fill_price
    ask_price = [fill_price+200, (bid*0.95).to_i].max

    sell_block(type: :limit, price: ask_price, qty: amount, base: base)
  end

  def deal_sell_first
    return unless valid_share_value

    price = Quote.good_price(based_on: :bid)
    return if price.zero?

    ask_rate, ask_share = 1, (0.04/Manager::DEALER)
    ask_rate += index * ask_share
    ask = ( price * 100 * ask_rate ).to_i

    return if ask == 0

    amount, fill_price = sell(type: :limit, price: ask, qty: Manager::SHARE)
    return 0 if amount.zero?

    base = amount * fill_price
    bid_price = [fill_price-200, (ask*1.05).to_i].min

    buy_block(type: :limit, price: bid_price, qty: amount, base: base)
  end

  def id
    "##{index}"
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

  def buy(type:, price:, qty:)
    puts "#{id} --> buy #{qty} at #{price}"

    if type == :limit
      order = client.buy(stock, price: price, qty: qty, type: type)[:id]
      resp = client.cancel(stock, order: order)
    elsif type == :immediate_or_cancel
      resp = client.buy(stock, price: price, qty: qty, type: type)
    else
      raise "Wrong type: #{type}"
    end

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
      share.increment_by( fill_qty )
      return fill_qty, fill_price
    end
  end

  def buy_block(type:, price:, qty:, base:)
    init_qty = qty
    sum = 0
    down_price = [100]
    pos = 0
    loop do
      puts "#{id} --> buy #{qty} at #{price}"

      if type == :limit
        order = client.buy(stock, price: price, qty: qty, type: type)[:id]
        resp = client.cancel(stock, order: order)
      elsif type == :immediate_or_cancel
        resp = client.buy(stock, price: price, qty: qty, type: type)
      else
        raise "Wrong type: #{type}"
      end

      fills = resp[:fills]
      next if fills.nil?

      fill_qty  = fills.map{|ha| ha['qty'].to_i}.sum
      fill_sum = fills.map{|ha| ha['price'].to_i * ha['qty'].to_i}.sum
      fill_price = (fill_sum/fill_qty.to_f).to_i rescue 0

      sum += fill_sum

      if qty == fill_qty
        puts "#{id} --> bought #{fill_qty} at #{fill_price}"
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
    share.increment_by( init_qty )
    @self_profit.increment_by(value)
    @transaction_count.increment_by(1)

    value = "+#{value}" if value >= 0
    puts "#{id} --> share: #{share.value} profit: #{profit.value} (#{value}, self_profit: #{@self_profit.value}, transaction_count: #{@transaction_count.value})"
  end

  def sell(type:, price:, qty:)
    puts "#{id} --> sell #{qty} at #{price}"

    if type == :limit
      order = client.sell(stock, price: price, qty: qty, type: type)[:id]
      resp = client.cancel(stock, order: order)
    elsif type == :immediate_or_cancel
      resp = client.sell(stock, price: price, qty: qty, type: type)
    else
      raise "Wrong type: #{type}"
    end

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
      share.increment_by( 0 - fill_qty )
      return fill_qty, fill_price
    end
  end

  def sell_block(type:, price:, qty:, base:)
    init_qty = qty
    sum = 0
    down_price = [100]
    pos = 0
    loop do
      puts "#{id} --> sell #{qty} at #{price}"

      if type == :limit
        order = client.sell(stock, price: price, qty: qty, type: type)[:id]
        resp = client.cancel(stock, order: order)
      elsif type == :immediate_or_cancel
        resp = client.sell(stock, price: price, qty: qty, type: type)
      else
        raise "Wrong type: #{type}"
      end

      fills = resp[:fills]
      next if fills.nil?

      fill_qty  = fills.map{|ha| ha['qty'].to_i}.sum
      fill_sum = fills.map{|ha| ha['price'].to_i * ha['qty'].to_i}.sum
      fill_price = (fill_sum/fill_qty.to_f).to_i rescue 0

      sum += fill_sum

      if qty == fill_qty
        puts "#{id} --> sold #{fill_qty} at #{fill_price}"
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
    share.increment_by( 0 - init_qty )
    @self_profit.increment_by(value)
    @transaction_count.increment_by(1)

    value = "+#{value}" if value >= 0
    puts "#{id} --> share: #{share.value} profit: #{profit.value} (#{value}, self_profit: #{@self_profit.value}, transaction_count: #{@transaction_count.value})"
  end

end

