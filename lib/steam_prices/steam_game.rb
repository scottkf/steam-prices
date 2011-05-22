module SteamPrices
    class Game
    
      include Updater
    
      attr_reader :app_id, :app_name, :store_link, :logo_link, :date_released, :price
    
      def initialize(app_name = nil, app_id = nil, store_link = nil, logo_link = nil, date_released = nil, price = nil)
        @app_id = app_id.to_i
        @app_name = app_name.to_s
        @store_link = store_link
        @logo_link = logo_link
        @date_released = date_released
        raise ArgumentError, "Expected: Money()" if price.class.name != 'Money' && price != nil
        @price = price
      end
      
      def update(currency = nil)
        return nil if !@app_name or @app_id == 0
        self.class.update_one(@app_name, @app_id, currency)
      end
      
    end
end