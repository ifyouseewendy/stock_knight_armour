class Quote
  include Mongoid::Document
  field :name,        type: String
  field :symbol,      type: String
  field :venue,       type: String
  field :bid,         type: Integer
  field :ask,         type: Integer
  field :bidSize,     type: Integer
  field :askSize,     type: Integer
  field :bidDepth,    type: Integer
  field :askDepth,    type: Integer
  field :last,        type: Integer
  field :lastSize,    type: Integer
  field :lastTrade,   type: String # Index by db.quotes.createIndex( { lastTrade: 1 }, { background: true } )
  field :quoteTime,   type: String
end
