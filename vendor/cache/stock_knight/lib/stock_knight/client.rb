module StockKnight
  class Client
    include HTTParty
    base_uri 'https://api.stockfighter.io/ob/api'

    class Parser::Simple < HTTParty::Parser
      def parse
        JSON.parse(body).with_indifferent_access rescue {error: body}
      end
    end

    parser Parser::Simple

    # Level specific info
    CONFIG = Struct.new(:account, :venue, :debug_output) do
      def validate!
        key = %i(account venue).detect{|k| self.public_send(k).nil? }
        raise ArgumentError, "#{key} should not be blank" unless key.nil?
      end
    end

    TYPES = [:limit, :market, :fill_or_kill, :immediate_or_cancel]

    attr_reader :apikey

    def initialize(apikey)
      @apikey = apikey
    end

    def config
      @config ||= CONFIG.new
    end

    def configure
      yield config

      config.validate!

      self.class.class_eval { debug_output STDOUT } if config.debug_output
    end

    def check_api_status
      self.class.get('/heartbeat', headers)
    end

    def check_venue_status
      self.class.get("/venues/#{config.venue}/heartbeat", headers)
    end

    def stocks
      self.class.get("/venues/#{config.venue}/stocks", headers)
    end

    def orders
      self.class.get("/venues/#{config.venue}/accounts/#{config.account}/orders", headers)
    end

    def orders_of(stock)
      self.class.get("/venues/#{config.venue}/accounts/#{config.account}/stocks/#{stock}/orders", headers)
    end

    def query(stock, order:)
      self.class.get("/venues/#{config.venue}/stocks/#{stock}/orders/#{order}", headers)
    end

    %i(buy sell).each do |opt|
      define_method opt do |stock, price:, qty:, type:|
        raise ArgumentError, "#{type} is not valid" unless TYPES.include?(type)

        order = {
          account: config.account,
          venue: config.venue,
          stock: stock,
          direction: opt,
          price: price,
          qty: qty,
          orderType: type.to_s.gsub('_', '-')
        }

        self.class.post(
          "/venues/#{config.venue}/stocks/#{stock}/orders",
          headers.merge({body: JSON.dump(order)})
        )
      end
    end

    def cancel(stock, order:)
      self.class.delete("/venues/#{config.venue}/stocks/#{stock}/orders/#{order}", headers)
    end

    def orderbook_of(stock)
      self.class.get("/venues/#{config.venue}/stocks/#{stock}", headers)
    end

    def quote_of(stock)
      self.class.get("/venues/#{config.venue}/stocks/#{stock}/quote", headers)
    end

    private

      def headers
        @_headers ||= { headers: { "X-Stockfighter-Authorization" => apikey } }
      end

  end
end
