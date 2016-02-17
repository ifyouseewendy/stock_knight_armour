require 'sinatra'

require 'mongoid'
$:.unshift File.join(__FILE__, "../config")
Mongoid.load!("config/mongoid.yml", :development)

class User
  include Mongoid::Document
  field :name, type: String
end

get '/' do
  "Hello world! #{User.count}"
end
