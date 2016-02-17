require_relative 'fetcher'
require_relative 'processor'
require_relative 'quote'

class Manager
  attr_reader :fetcher, :processor

  def initialize
    @fetcher   = Fetcher.pool(args: self)   # size default to system cores count
    @processor = Processor.pool

    clean_db
  end

  def dispatch
    puts '--> Manager: start dispatch'
    fetcher.async.fetch
  end

  def assign(work)
    puts '--> Manager: start assign'
    processor.async.process(work)
  end

  private

    def clean_db
      Quote.destroy_all
    end
end

