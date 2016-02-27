#!/usr/bin/env ruby

require "bundler/setup"
require 'mongoid'
Mongoid.load!("config/mongoid.yml", :development)
require File.expand_path('../../models/models', __FILE__)

if ARGV[0] == 'new'
  puts "--> Cleaning"

  DbCounter.destroy_all
  Quote.destroy_all
end

class Configuration
  FETCHER   = 2
  PROCESSOR = 2
  DEALER    = 8
  SHARE     = 250
end

def good_price(based_on:, sample_count:)
  return 0 if Quote.count < sample_count

  Quote.order_by(lastTrade: :desc).first.try(based_on)
end


manager = Manager.new(:irrational_exuberance_dealer)

puts '--> Start watching'
watcher = Thread.new do
  loop do
    manager.dispatch
  end
end

start_price = 0
while start_price.zero?
  start_price = ( good_price(based_on: :bid, sample_count: 1) * 100 * 1.1 ).to_i
end
puts "--> Get start_price: #{start_price}"

target_price = 100*(start_price + 100_000)

puts "#"*40
puts "--> Raising"
price = start_price
futures = []
loop do
  manager.deal do |dealers|
    dealers.each_with_index do |dealer, idx|
      futures << dealer.future.buy_first_nail_price(to: price)

      # if idx.even?
      #   dealer.async.buy_first_nail_price(to: price)
      # else
      #   dealer.async.sell_first_nail_price(to: price)
      # end
    end
  end

  break if price > target_price

  price = (price * 2).to_i
end

begin
  futures.each(&:value)
rescue => e
  puts e.message
end

puts "#"*40
puts "--> Depressing"
price = start_price
loop do
  manager.deal do |dealers|
    dealers.each_with_index do |dealer, idx|
      if idx.even?
        dealer.async.buy_first_nail_price(to: price)
      else
        dealer.async.sell_first_nail_price(to: price)
      end
    end
  end
end

watcher.join
