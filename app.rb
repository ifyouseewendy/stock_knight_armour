require 'sinatra'
require 'celluloid/current'
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
  include Celluloid

  attr_reader :client, :stock

  def initialize
    @client = StockKnight::Client.new(ENV['APIKEY'])

    @client.configure do |config|
      config.account      = ENV['ACCOUNT']
      config.venue        = ENV['VENUE']
      config.debug_output = true #  Log request and response info
    end

    @stock = 'FOOBAR'
  end

  def fetch

  end
end

get '/' do
  "Hello world! #{User.count}"
end
