require 'sinatra'
require 'mongoid'
Mongoid.load!("config/mongoid.yml", :development)
require 'models/models'

get '/' do
  "Hello world! #{Quote.count}"
end
