class DbCounter
  class MetaCounter
    include Mongoid::Document
    field :counter, type: Integer, default: 0
    field :name,    type: String
  end

  attr_reader :criteria

  def initialize(name)
    id = MetaCounter.find_or_create_by(name: name).id
    @criteria = MetaCounter.where(id: id)
  end

  def increment_by(val)
    criteria.inc(counter: val)
  end

  def value
    criteria.first.counter
  end

  def self.destroy_all
    MetaCounter.destroy_all
  end
end
