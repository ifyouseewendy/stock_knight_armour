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
    def buy_in_price
      return 0 if Quote.count < 6

      sample = Quote.order_by(lastTrade: :desc).limit(6)

      last_bid = sample.first.bid

      bids    = sample.pluck(:bid).reject(&:zero?).sort
      range   = bids.count / 3
      avg_bid = bids[range, range].avg

      valid_rate = 0.05
      if last_bid >= avg_bid*(1-valid_rate) && last_bid <= avg_bid*(1+valid_rate)
        [last_bid, avg_bid].avg
      else
        avg_bid
      end
    end
  end
end
