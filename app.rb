require 'sinatra'
require 'mongoid'
Mongoid.load!("config/mongoid.yml", :development)
require File.expand_path('../models/models', __FILE__)

get '/' do
  erb :index
end
