require 'terminal-table'

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
    criteria.first.try(:counter) || 0
  end

  class << self
    def destroy_all
      MetaCounter.destroy_all
    end

    def stats
      fields = ['round', 'share', 'profit']
      table = Terminal::Table.new do |t|
        t << [''] + fields
        t << :separator
        count = (MetaCounter.count / 3) - 1
        ( ['total'] + (0...count).to_a ).each do |id|
          row = [id]
          fields.each do |field|
            row << MetaCounter.where(name: "#{field}_#{id}").first.try(:counter)
          end
          t << row
        end
      end

      puts table
    end
  end
end
