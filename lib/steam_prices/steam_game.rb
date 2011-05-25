module SteamPrices
    class Game
    
      include Updater
    
      attr_reader :app_id, :app_name, :store_link, :logo_link, :date_released, :status, :category
      attr_accessor :price
    
      def initialize(app_name = nil, app_id = nil, store_link = nil, logo_link = nil, date_released = nil, price = nil)
        @app_id = app_id.to_i
        @app_name = app_name.to_s
        @store_link = store_link ||= "http://store.steampowered.com/app/12312312"
        @category = (@store_link.match(/(.*store\.steampowered\.com\/app\/[\d]+)/) ? GAME : PACK)
        @logo_link = logo_link
        @date_released = date_released
        raise ArgumentError, "Expected: Money()" if price.class.name != 'Money' && price != nil
        @price = price
      end
      
      def update(currency = nil)
        return nil if !@app_name or @app_id == 0
        self.class.update_one(@category, @app_name, @app_id, currency)
      end
      
    end
end