require 'celluloid/current'
require_relative 'quote'

class Processor
  include Celluloid

  def initialize
    puts '--> Processor: initialize'
  end

  def process(work)
    puts '--> Processor: start process'
    Quote.create work.except(:ok)
    puts '--> Processor: end process'
  end
end

