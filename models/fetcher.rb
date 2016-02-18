require 'celluloid/current'
require 'stock_knight'

class Fetcher
  include Celluloid

  attr_reader :manager, :client, :stock

  def initialize(manager)
    # puts '--> Fetcher: initialize'
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
      puts "--> Fetcher: failed fetch, #{work[:error]}"
    end
  end
end

