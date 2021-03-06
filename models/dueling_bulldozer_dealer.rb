class DuelingBulldozerDealer < Dealer
  def deal_buy_low_first
    return unless valid_share_value

    price = good_price(based_on: :ask)
    return if price.zero?

    bid = ( price * 100 * 0.7 ).to_i

    amount, fill_price = buy(type: :limit, price: bid, qty: Configuration::SHARE)
    return 0 if amount.zero?

    base = amount * fill_price
    ask_price = ( price * 100 * 0.95 ).to_i

    sell_block(type: :limit, price: ask_price, qty: amount, base: base)
  end

  def deal_sell_high_first
    return unless valid_share_value

    price = good_price(based_on: :bid)
    return if price.zero?

    ask = ( price * 100 * 1.3 ).to_i

    amount, fill_price = sell(type: :limit, price: ask, qty: Configuration::SHARE)
    return 0 if amount.zero?

    base = amount * fill_price
    bid_price = ( price * 100 * 1.05 ).to_i

    buy_block(type: :limit, price: bid_price, qty: amount, base: base)
  end

  def deal_buy_first
    return unless valid_share_value

    price = good_price(based_on: :ask)
    return if price.zero?

    bid_rate, bid_share = 1, (0.04/Configuration::DEALER)
    bid_rate -= index * bid_share
    bid = ( price * 100 * bid_rate ).to_i

    return if bid == 0

    amount, fill_price = buy(type: :limit, price: bid, qty: Configuration::SHARE)
    return 0 if amount.zero?

    base = amount * fill_price
    ask_price = [fill_price+200, (bid*0.95).to_i].max

    sell_block(type: :limit, price: ask_price, qty: amount, base: base)
  end

  def deal_sell_first
    return unless valid_share_value

    price = good_price(based_on: :bid)
    return if price.zero?

    ask_rate, ask_share = 1, (0.04/Configuration::DEALER)
    ask_rate += index * ask_share
    ask = ( price * 100 * ask_rate ).to_i

    return if ask == 0

    amount, fill_price = sell(type: :limit, price: ask, qty: Configuration::SHARE)
    return 0 if amount.zero?

    base = amount * fill_price
    bid_price = [fill_price-200, (ask*1.05).to_i].min

    buy_block(type: :limit, price: bid_price, qty: amount, base: base)
  end

  def good_price(based_on:, sample_count: 3)
    return 0 if Quote.count < sample_count

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
