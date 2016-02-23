class Manager
  attr_reader :fetcher, :processor, :dealers, :start_time
  attr_accessor :counter, :profit, :share

  def initialize(dealer)
    @fetcher    = Fetcher.pool(size: Configuration::FETCHER, args: self)   # size default to system cores count
    @processor  = Processor.pool(size: Configuration::PROCESSOR)

    @counter    = 0
    @start_time = Time.now.to_i

    @profit     = DbCounter.new('profit_total')
    @share      = DbCounter.new('share_total')
    @round      = DbCounter.new('round_total')

    klass = dealer.to_s.camelcase.constantize
    @dealers    = Configuration::DEALER.times.with_index.map{|i, _| klass.new(i, @profit, @share, @round) }
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
    yield dealers
  end

  def clean_db
    Quote.destroy_all
  end
end

