class Quote
  include Mongoid::Document
  field :name,        type: String
  field :symbol,      type: String
  field :venue,       type: String
  field :bid,         type: Float,   default: 0
  field :ask,         type: Float,   default: 0
  field :bidSize,     type: Integer, default: 0
  field :askSize,     type: Integer, default: 0
  field :bidDepth,    type: Integer, default: 0
  field :askDepth,    type: Integer, default: 0
  field :last,        type: Float,   default: 0
  field :lastSize,    type: Integer, default: 0
  field :lastTrade,   type: String # Index by db.quotes.createIndex( { lastTrade: 1 }, { background: true, unique: true } )
  field :quoteTime,   type: String

  class << self
    # buy first use based_on: :ask
    # sell first use based_on: :bid
    def good_price(based_on:)
      return 0 if Quote.count < 3

      sample = Quote.order_by(lastTrade: :desc).limit(6)
      last_price = sample.first.try(based_on)

      prices    = sample.pluck(based_on).reject(&:zero?).sort
      range     = prices.count / 3
      avg_price = prices[range, range].avg

      valid_rate = 0.05
      if last_price >= avg_price*(1-valid_rate) && last_price <= avg_price*(1+valid_rate)
        # [last_price, avg_price].avg
        # last_price
        avg_price
      else
        avg_price
      end
    end
  end
end
