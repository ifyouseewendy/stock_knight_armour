class Manager
  attr_reader :fetcher, :processor, :dealers, :start_time
  attr_accessor :counter, :profit, :share

  DEALER_COUNT = 16

  def initialize
    @fetcher    = Fetcher.pool(size: 2, args: self)   # size default to system cores count
    @processor  = Processor.pool(size: 2)

    @counter    = 0
    @start_time = Time.now.to_i

    @profit     = Profit.new
    @share      = Profit.new
    @dealers    = DEALER_COUNT.times.map{ Dealer.new(@profit, @share) }
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
    dealers.each_with_index do |dealer, idx|
      if idx.even?
        dealer.async.deal_buy_first(index: idx)
      else
        dealer.async.deal_sell_first(index: idx)
      end
    end
  end

  def clean_db
    Quote.destroy_all
  end
end

