class Manager
  attr_reader :fetcher, :processor, :dealers, :start_time
  attr_accessor :counter, :profit

  DEALER_COUNT = 16

  def initialize
    @fetcher    = Fetcher.pool(size: 2, args: self)   # size default to system cores count
    @processor  = Processor.pool(size: 2)

    @counter    = 0
    @start_time = Time.now.to_i

    @profit     = Profit.new
    @dealers    = DEALER_COUNT.times.map{ Dealer.new(@profit) }
  end

  def dispatch
    # puts '--> Manager: start dispatch'
    fetcher.async.fetch
  end

  def assign(work)
    # puts '--> Manager: start assign'
    processor.async.process(work)

    self.counter += 1
  end

  def terminate
    fetcher.terminate
    processor.terminate

    seconds = Time.now.to_i - start_time
    count = (counter / seconds.to_f).round(2)

    puts "--> Run #{seconds}s, get #{counter} iterations, avg #{count} i/s"
  end

  def deal
    price = Quote.buy_in_price
    return if price.zero?

    # bid: 0.95 ~ 1.05
    bid_rate, bid_share, bids = 1, (0.04/DEALER_COUNT), []
    DEALER_COUNT.times do
      bids << ( price * 100 * bid_rate ).to_i
      bid_rate += bid_share
    end

    # ask: 1.05 ~ 1.0
    # ask_rate, ask_share, asks = 1.04, (0/DEALER_COUNT), []
    # bids.each do |bid|
    #   asks << ( bid * ask_rate).to_i
    #   ask_rate += ask_share
    # end

    dealers.each_with_index do |dealer, idx|
      sleep(1)
      dealer.async.deal(bid: bids[idx], ask: 0)
    end
  end

  def clean_db
    Quote.destroy_all
  end
end

