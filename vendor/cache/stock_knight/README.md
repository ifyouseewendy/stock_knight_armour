# StockKnight

An API client strikes against [StockFighter](www.stockfighter.io).

## Installation

```sh
$ gem install stock_knight
```

## API

Initialization

```ruby
client = StockKnight::Client.new(ENV['APIKEY'])

client.configure do |config|
  config.account      = ENV['ACCOUNT']
  config.venue        = ENV['VENUE']
  config.debug_output = true #  Log request and response info
end

stock = 'FOOBAR'
```

Check A Venue Is Up

> https://starfighter.readme.io/docs/venue-healthchecke

```ruby
client.check_venue_status
```

Stocks on a Venue

> https://starfighter.readme.io/docs/list-stocks-on-venue

```ruby
client.stocks
```

Status For All Orders

> https://starfighter.readme.io/docs/status-for-all-orders

```ruby
client.orders
```

Status For All Orders In A Stock

> https://starfighter.readme.io/docs/status-for-all-orders-in-a-stock

```ruby
client.orders_of(stock)
```

Status For An Existing Order

> https://starfighter.readme.io/docs/status-for-an-existing-order

```ruby
client.query stock, order: '123'
```

A New Order For A Stock

> https://starfighter.readme.io/docs/place-new-order

```ruby
client.buy  stock, price: 100, qty: 10, type: :limit
client.buy  stock, price: 200, qty: 10, type: :market
client.sell stock, price: 300, qty: 10, type: :fill_or_kill
client.sell stock, price: 400, qty: 10, type: :immediate_or_cancel
```

Cancel An Order

> https://starfighter.readme.io/docs/cancel-an-order

```ruby
client.cancel stock, order: '123'
```

### Stock

The Orderbook For A Stock

> https://starfighter.readme.io/docs/get-orderbook-for-stock

```ruby
client.orderbook_of(stock)
```

A Quote For A Stock

> https://starfighter.readme.io/docs/a-quote-for-a-stock

```ruby
client.quote_of(stock)
```

### API status

> https://starfighter.readme.io/docs/heartbeat

```ruby
account.check_api_status
```

### GM API

> https://discuss.starfighters.io/t/the-gm-api-how-to-start-stop-restart-resume-trading-levels-automagically/143

```ruby
gm = StockKnight::GameMaster.new(ENV['APIKEY'])

gm.start(:firts_steps)
gm.stop(instance_id)
gm.active?(instance_id)
gm.resume(instance_id)
gm.restart(instance_id)
gm.levels
```

Or you can use thor to do level controlling on the command line.

```
Commands:
  Thorfile help [COMMAND]                     # Describe available commands or one specific command
  Thorfile restart --instance-id=INSTANCE_ID  #
  Thorfile start --level=LEVEL                #
  Thorfile stop --instance-id=INSTANCE_ID     #
```

## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).

