module StockKnight
  class GameMaster
    include HTTParty
    base_uri 'https://www.stockfighter.io/gm'

    class Parser::Simple < HTTParty::Parser
      def parse
        JSON.parse(body).with_indifferent_access rescue {error: body}
      end
    end

    parser Parser::Simple

    attr_reader :apikey

    def initialize(apikey)
      @apikey = apikey
    end

    def start(level)
      self.class.post("/levels/#{level}", headers)
    end

    def stop(instance_id)
      self.class.post("/instances/#{instance_id}/stop", headers)
    end

    def active?(instance_id)
      self.class.get("/instances/#{instance_id}", headers)[:state] == "open"
    end

    def resume(instance_id)
      self.class.post("/instances/#{instance_id}/resume", headers)
    end

    def restart(instance_id)
      self.class.post("/instances/#{instance_id}/restart", headers)
    end

    def levels
      self.class.get("/levels", headers)
    end

    private

      def headers
        @_headers ||= { headers: { "X-Stockfighter-Authorization" => apikey } }
      end

  end
end
