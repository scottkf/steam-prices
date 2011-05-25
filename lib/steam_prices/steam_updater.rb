module SteamPrices
  module Updater
    


    def self.included(base)
      base.extend ClassMethods
    end
    
    
    EXCEPTIONS = {
      #warhammer retribution
      56400 => 56437,
      #lost coast
      340 => 0.00,
    }
    
    PACK = 996
    GAME = 998
  


    module ClassMethods
      def currency(c)
        return (c.nil? && SteamPrices::Country.currencies) || { c => SteamPrices::Country.get_country(c) }
      end
    

      def status(price)
        (price.empty? ? :not_found : :ok)
      end
      
      def get_price(node)
        # remove strikethrough prices
        node.search('span').remove
        price = node.text.gsub(/[\W_]/, '')
      end
      
      

      def update_one_game(name, app_id, currency = nil)
        self.update_one(GAME, name, app_id, currency)
      end
      
      def update_one_pack(name, app_id, currency = nil)
        self.update_one(PACK, name, app_id, currency)
      end

      # update a single one
      def update_one(category, name, app_id, currency = nil)      
        prices = Hash.new

        @countries = self.currency(currency) if !currency.nil?

        @countries.each do |curr, country|
          doc = Nokogiri::HTML(open(URI.encode("http://store.steampowered.com/search/results?sort_by=Name&sort_order=ASC&category1=#{category}&cc=#{country}&v6=1&page=1&term=#{name}")))
          node = doc.xpath('.//a[regex(., "/store\.steampowered\.com\/(app|sub)\/' + app_id.to_s + '/")]', Class.new {
            def regex node_set, regex
              node_set.find_all { |node| node['href'] =~ /#{regex}/ }
            end
          }.new).search('.search_price')
          price = self.get_price(node)
          status = (node.empty? ? :bad_request : self.status(price))
          prices[curr] = { :price => (status == :ok ? Money.new(price.to_f, curr) : nil), :status => status }
        end
        prices
      end
      
      def update_everything(currency = nil, display = true)
        games = self.update_all_games(currency, display)
        games.merge!(self.update_all_packs(currency, display))
      end
      
      def update_all_games(currency = nil, display = true)
        self.update_all(GAME, currency, display)
      end
      
      def update_all_packs(currency = nil, display = true)
        self.update_all(PACK, currency, display)
      end
      
      # display stolen from https://github.com/spezifanta/SteamCalculator-Scripts/blob/master/getGames
      def update_all(category, currency = nil, display = true)
        games = Hash.new
      
        @countries = self.currency(currency) if !currency.nil?
      
        @countries.each do |curr, country|
          doc = Nokogiri::HTML(open(URI.encode("http://store.steampowered.com/search/results?sort_by=Name&sort_order=ASC&category1=#{category}&cc=#{country}&v6=1&page=1")))
          gamesPerPage, totalGames = doc.search('.search_pagination_left')[0].text.match(/showing\s\d+\s-\s(\d+)\sof\s(\d+)/m).captures

          totalPages = (totalGames.to_i / gamesPerPage.to_i).ceil

          exceptions = Array.new


          for i in 1..totalPages

            if display then
              printf "\n   Loading '#{country}', page %02d of %02d                                                \n", i, totalPages
              printf "   Entries % 5d - % 5d of %d                                                \n", ((i - 1) * gamesPerPage.to_i + 1), (i * gamesPerPage.to_i), totalGames
              printf "+---------+---------+---------------+--------------------------------------------\n"
              printf "|  AppID  |  Price  |    Release    |                 Game Title                 \n"
              printf "+---------+---------+---------------+--------------------------------------------\n"
            end
            
            doc.search('.search_result_row').each do |game|
              url = game.attr('href').match(/(.*store\.steampowered\.com\/app|sub\/([\d]+)\/)/)
              # for things like /sale/
              if !url then
                games[game.attr('href')] = { :status => :bad_request }
              else
                link, app_id = url.captures
                
                #remove retail price and put sale price
                price = self.get_price(game.search('.search_price'))
                date = game.search('.search_released').text
                name = game.search('h4').text
                logo = game.search('.search_capsule img').attr('src').value

                print "|% 8s |" % app_id + "% 8.2f |" % (price.to_f / 100) + "% 14s |" % date if display
                printf " %s%" + (43 - name[0,43].length).to_s + "s\n", name[0,42], " " if display
                status = self.status(price)
                game = SteamPrices::Game.new(name, app_id, link, logo, date, (status == :ok ? Money.new(price.to_f, curr) : nil))
                
                games[app_id.to_i] = Hash.new if !games[app_id.to_i]
                games[app_id.to_i][curr] = { :game => game, :status => status }
              end
            end

            printf "+---------+---------+---------------+--------------------------------------------\n\n" if display
            #grab the next page only if we're not on the last page
            doc = Nokogiri::HTML(open(URI.encode("http://store.steampowered.com/search/results?sort_by=Name&sort_order=ASC&category1=998&cc=#{country}&v6=1&page=#{i+1}"))) if i != totalPages

          end
          
          # check if there are any special cases
          EXCEPTIONS.each do |app_id, v|
            if games.key? app_id then
              
              games[app_id].each do |currency, game|
                if v.class.name == 'Fixnum' then
                  # it's an app id, so we need to either fetch the real price, or get it if we already have it
                  price = (games.key?(v) ? games[v][currency][:game].price : self.update_one(game[:game].app_name, v, currency)[currency][:price])
                elsif v.class.name == 'Float' then
                  # it's a price
                  price = v
                else
                  # it's a sub
                  # get the price of the sub
                end
                # update the price
                game[:game].price = price
                
              end
            end
          end
          
        end
        games      
      end
    end
    

 end
end