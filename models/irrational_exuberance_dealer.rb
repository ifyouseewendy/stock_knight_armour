class IrrationalExuberanceDealer < Dealer
  def buy_first_nail_price(to:)
    price = to
    amount, fill_price = buy(type: :limit, price: price, qty: Configuration::SHARE)
    return false if amount.zero?

    base = amount * fill_price
    ask_price = (price * 1.2).to_i

    sell_block(type: :limit, price: ask_price, qty: amount, base: base)
    return true
  end

  def sell_first_nail_price(to:)
    price = to
    amount, fill_price = sell(type: :limit, price: price, qty: Configuration::SHARE)
    return false if amount.zero?

    base = amount * fill_price
    bid_price = (price * 0.8).to_i

    buy_block(type: :limit, price: bid_price, qty: amount, base: base)
    return true
  end

  def deal_buy_first
    puts "--> deal_buy_first"
    # return unless valid_share_value

    price = good_price(based_on: :bid, sample_count: 1)
    return if price.zero?

    bid_rate = 0.5
    bid = ( price * 100 * bid_rate ).to_i

    puts "--> deal_buy_first: bid #{bid}"
    return if bid == 0

    amount, fill_price = buy(type: :limit, price: bid, qty: Configuration::SHARE)
    puts "--> deal_buy_first: amount #{amount}"
    return 0 if amount.zero?

    base = amount * fill_price
    ask_price = fill_price + 200

    sell_block(type: :limit, price: ask_price, qty: amount, base: base)
  end

  def deal_sell_first
    # return unless valid_share_value

    price = good_price(based_on: :bid, sample_count: 1)
    return if price.zero?

    ask_rate = 0.5
    ask = ( price * 100 * ask_rate ).to_i

    return if ask == 0

    amount, fill_price = sell(type: :limit, price: ask, qty: Configuration::SHARE)
    return 0 if amount.zero?

    base = amount * fill_price
    bid_price = fill_price - 200

    buy_block(type: :limit, price: bid_price, qty: amount, base: base)
  end

end
