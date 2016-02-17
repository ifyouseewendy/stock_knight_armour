require 'sinatra'
require 'celluloid/current'
require 'stock_knight'
require 'mongoid'
$:.unshift File.join(__FILE__, "../config")
Mongoid.load!("config/mongoid.yml", :development)

class Quote
  include Mongoid::Document
  field :name,        type: String
  field :symbol,      type: String
  field :venue,       type: String
  field :bid,         type: Integer
  field :ask,         type: Integer
  field :bidSize,     type: Integer
  field :askSize,     type: Integer
  field :bidDepth,    type: Integer
  field :askDepth,    type: Integer
  field :last,        type: Integer
  field :lastSize,    type: Integer
  field :lastTrade,   type: Time
  field :quoteTime,   type: Time
end

class Manager
  attr_reader :fetcher, :processor

  def initialize
    @fetcher   = Fetcher.pool(args: self)   # size default to system cores count
    @processor = Processor.pool
  end

  def dispatch
    puts '--> Manager: start dispatch'
    fetcher.async.fetch
  end

  def assign(work)
    puts '--> Manager: start assign'
    processor.async.process(work)
  end
end

class Fetcher
  include Celluloid

  attr_reader :manager, :client, :stock

  def initialize(manager)
    puts '--> Fetcher: initialize'
    @manager = manager

    @client = StockKnight::Client.new(ENV['APIKEY'])

    @client.configure do |config|
      config.account      = ENV['ACCOUNT']
      config.venue        = ENV['VENUE']
      config.debug_output = false #  Log request and response info
    end

    @stock = ENV['STOCK']
  end

  def fetch
    puts '--> Fetcher: start fetch'
    work = client.quote_of(stock)

    if work[:ok]
      puts '--> Fetcher: done fetch'
      manager.assign(work)
    else
      puts "Failed fethcing: #{work[:error]}"
    end
  end
end

class Processor
  include Celluloid

  def initialize
    puts '--> Processor: initialize'
  end

  def process(work)
    puts '--> Processor: start process'
    # Write to mongo
    p work
    puts '--> Processor: end process'
  end
end

manager = Manager.new
loop do
  manager.dispatch
end

# get '/' do
#   "Hello world! #{User.count}"
# end
