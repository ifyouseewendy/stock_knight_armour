require 'thor'
require_relative 'lib/stock_knight'

class GameCommander < Thor
  desc 'start', ''
  option :level, required: true
  def start
    gm = StockKnight::GameMaster.new(ENV['APIKEY'])
    resp = nil

    5.times do
      resp = gm.start(options[:level])

      unless resp[:ok]
        puts resp[:error]
        next
      end
    end

    if resp[:ok]
      puts <<-HERE
        --> Succeed start level
        instance_id: #{resp[:instanceId]}
            account: #{resp[:account]}
             venues: #{resp[:venues].join(', ')}
            tickers: #{resp[:tickers].join(', ')}
      HERE
    else
      puts "--> Failed start level"
    end
  end

  desc 'stop', ''
  option :instance_id, required: true
  def stop
    gm = StockKnight::GameMaster.new(ENV['APIKEY'])
    puts gm.stop(options[:instance_id])
  end

  desc 'restart', ''
  option :instance_id, required: true
  def restart
    gm = StockKnight::GameMaster.new(ENV['APIKEY'])
    puts gm.restart(options[:instance_id])
  end
end

GameCommander.start(ARGV)
