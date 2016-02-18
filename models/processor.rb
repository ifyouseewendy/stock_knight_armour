require 'celluloid/current'
require_relative 'quote'

class Processor
  include Celluloid

  def initialize
    # puts '--> Processor: initialize'
  end

  def process(work)
    # puts '--> Processor: start process'
    begin
      Quote.create work.except(:ok)
    rescue Mongo::Error::OperationFailure => e
    end
    # puts '--> Processor: end process'
  end
end

