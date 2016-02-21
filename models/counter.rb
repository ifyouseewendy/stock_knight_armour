require 'concurrent'

class Counter
  def initialize
    @counter = Concurrent::AtomicFixnum.new(0)
  end

  def increment_by(val)
    @counter.update{|obj| obj + val}
  end

  def value
    @counter.value
  end
end
