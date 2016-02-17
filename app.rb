require 'sinatra'
require 'mongoid'
Mongoid.load!("config/mongoid.yml", :development)
require File.expand_path('../models/models', __FILE__)

get '/' do
  erb :index
end

get '/quotes' do
  quotes = Quote.all.to_a

  {
    xData: (1..quotes.count).to_a,
    datasets: [
      {
        name: 'Last',
        data: quotes.map(&:last),
        type: 'line',
      },
      {
        name: 'Bid',
        data: quotes.map(&:bid),
        type: 'line',
      },
      {
        name: 'BidDepth',
        data: quotes.map(&:bidDepth),
        type: 'area',
      },
      {
        name: 'Ask',
        data: quotes.map(&:ask),
        type: 'line',
      },
      {
        name: 'AskDepth',
        data: quotes.map(&:askDepth),
        type: 'area',
      }
    ]
  }.to_json
end
