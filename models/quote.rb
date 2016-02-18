class Quote
  include Mongoid::Document
  field :name,        type: String
  field :symbol,      type: String
  field :venue,       type: String
  field :bid,         type: Integer, default: 0
  field :ask,         type: Integer, default: 0
  field :bidSize,     type: Integer, default: 0
  field :askSize,     type: Integer, default: 0
  field :bidDepth,    type: Integer, default: 0
  field :askDepth,    type: Integer, default: 0
  field :last,        type: Integer, default: 0
  field :lastSize,    type: Integer, default: 0
  field :lastTrade,   type: String # Index by db.quotes.createIndex( { lastTrade: 1 }, { background: true, unique: true } )
  field :quoteTime,   type: String
end
