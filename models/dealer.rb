require 'celluloid/current'
require 'stock_knight'

class Dealer
  include Celluloid

  attr_reader :client, :stock, :profit, :share, :round, :index

  def initialize(index, profit, share, round)
    initialize_client

    @index  = index
    @profit = profit
    @share  = share
    @round  = round
    @self_profit = DbCounter.new("profit_#{index}")
    @self_share = DbCounter.new("share_#{index}")
    @self_round = DbCounter.new("round_#{index}")
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
    share.increment_by(init_qty)
    round.increment_by(1)

    @self_profit.increment_by(value)
    @self_share.increment_by(init_qty)
    @self_round.increment_by(1)

    value = "+#{value}" if value >= 0
    puts "#{id} --> share: #{share.value} profit: #{profit.value} (#{value}, self_profit: #{@self_profit.value}, self_round: #{@self_round.value})"
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
    round.increment_by(1)

    @self_profit.increment_by(value)
    @self_share.increment_by( 0 - init_qty )
    @self_round.increment_by(1)

    value = "+#{value}" if value >= 0
    puts "#{id} --> share: #{share.value} profit: #{profit.value} (#{value}, self_profit: #{@self_profit.value}, self_round: #{@self_round.value})"
  end

end

