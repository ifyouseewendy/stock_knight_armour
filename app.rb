require 'sinatra'
require 'mongoid'
Mongoid.load!("config/mongoid.yml", :development)
require File.expand_path('../models/models', __FILE__)

get '/' do
  erb :index
end

get '/quotes' do
  {
    xData: [1,2,3,4,5],
    datasets: [
      {
        name: 'Last',
        data: [10, 20, 50, 40, 30],
        type: 'line',
        unit: '',
      },
      {
        name: 'Bid',
        data: [10, 20, 50, 40, 30],
        type: 'line',
        unit: '',
      },
      {
        name: 'BidDepth',
        data: [10, 20, 50, 40, 30],
        type: 'area',
        unit: '',
      },
      {
        name: 'Ask',
        data: [10, 20, 50, 40, 30],
        type: 'line',
        unit: '',
      },
      {
        name: 'AskDepth',
        data: [10, 20, 50, 40, 30],
        type: 'area',
        unit: '',
      },
    ]
  }.to_json
end
