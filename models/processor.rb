require 'celluloid/current'
require_relative 'quote'

class Processor
  include Celluloid

  def initialize
    # puts '--> Processor: initialize'
  end

  def process(work)
    work[:last] = (work[:last].to_f / 100.0).round(2)
    work[:ask]  = (work[:ask].to_f / 100.0).round(2)
    work[:bid]  = (work[:bid].to_f / 100.0).round(2)

    begin
      Quote.create work.except(:ok)
    rescue Mongo::Error::OperationFailure => e
    end
  end
end

