require 'httparty'
require 'active_support/core_ext/hash/indifferent_access'
require 'json'

require "stock_knight/version"
require "stock_knight/client"
require "stock_knight/game_master"

begin
  require "pry"
  require 'dotenv'
  Dotenv.load if defined? Dotenv
rescue LoadError
end
