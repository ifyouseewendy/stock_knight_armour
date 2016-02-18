require 'sinatra'
require 'mongoid'
Mongoid.load!("config/mongoid.yml", :development)
require File.expand_path('../models/models', __FILE__)

get '/' do
  erb :index
end

get '/quotes' do
  quotes = Quote.order_by(lastTrade: :asc).to_a

  {
    xData: (1..quotes.count).to_a,
    datasets: [
      {
        name: 'last',
        data: quotes.map(&:last),
      },
      {
        name: 'lastSize',
        data: quotes.map(&:lastSize),
      },
      {
        name: 'bid',
        data: quotes.map(&:bid),
      },
      {
        name: 'bidSize',
        data: quotes.map(&:bidSize),
      },
      {
        name: 'bidDepth',
        data: quotes.map(&:bidDepth),
      },
      {
        name: 'ask',
        data: quotes.map(&:ask),
      },
      {
        name: 'askSize',
        data: quotes.map(&:askSize),
      },
      {
        name: 'askDepth',
        data: quotes.map(&:askDepth),
      },
    ]
  }.to_json
end
