require_relative 'fetcher'
require_relative 'processor'
require_relative 'quote'
require_relative 'dealer'

class Manager
  attr_reader :fetcher, :processor, :dealer, :start_time
  attr_accessor :counter

  def initialize
    @fetcher   = Fetcher.pool(size: 128, args: self)   # size default to system cores count
    @processor = Processor.pool(size: 64)
    @dealer    = Dealer.pool

    @counter   = 0
    @start_time = Time.now.to_i

    clean_db
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
    dealer.async.deal
  end

  private

    def clean_db
      Quote.destroy_all
    end
end

