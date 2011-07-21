module SteamPrices
  module Updater
    


    def self.included(base)
      base.extend ClassMethods
    end
    
    
    EXCEPTIONS = {
      #lost coast
      340 => 0.00,
    }
    
    CATEGORIES = {
      :pack => 996,
      :game => 998,
      :dlc => 21
    }
  


    module ClassMethods
      def currency(c)
        return (c.nil? && SteamPrices::Country.currencies) || { c => SteamPrices::Country.get_country(c) }
      end
    

      def status(price)
        (price == nil ? :not_found : :ok)
      end
      
      def get_price(node)
        # remove strikethrough prices
        node.search('span').remove
        return 0 if node.text.match(/FREE/i)
        return nil if node.text.empty?
        if node.text.match /--/
          price = node.text.match(/(\d+)(\.|,)--/i)[1]+"00"
        else
          price = node.text.match(/(\d+(\.|,)\d\d)/i)
          price = price[0] if price.is_a? MatchData
          price.gsub!(/(\.|,)/, '') if price != nil 
        end
        price.to_i
      end
      
      def get_original_price(node)
        price = node.search('strike').text.match(/(\d+)(\.|,)(\d\d)/i)
        return nil if price.nil?
        price = price.captures
        (price[0] + price[2]).to_i
      end
      
      def get_exception_price()
      end

      def update_one_game(name, app_id, currency = nil)
        self.update_one(CATEGORIES[:game], name, app_id, currency)
      end
      
      def update_one_pack(name, app_id, currency = nil)
        self.update_one(CATEGORIES[:pack], name, app_id, currency)
      end

      # update a single one
      def update_one(category, name, app_id, currency = nil)      
        prices = Hash.new

        @countries = self.currency(currency)

        @countries.each do |curr, country|
          if EXCEPTIONS.key? app_id then
            v = EXCEPTIONS[app_id]
            case v.class.name
            when 'Fixnum'
              p = self.update_one(category, name, v, curr)
              price = p[curr][:price]
              status = p[curr][:status]
            when 'Float'
              # it's a price
              price = Money.new(v, curr)
              status = :ok
            else
              # it's a sub
              # get the price of the sub
            end   
            prices[curr] = { :price => price, :status => status, :original_price => nil }         
          else
            doc = Nokogiri::HTML(open(URI.encode("http://store.steampowered.com/search/results?sort_by=Name&sort_order=ASC&category1=#{category}&cc=#{country}&v6=1&page=1&term=#{name}")))
            node = doc.xpath('.//a[regex(., "/store\.steampowered\.com\/(app|sub)\/' + app_id.to_s + '/")]', Class.new {
              def regex node_set, regex
                node_set.find_all { |node| node['href'] =~ /#{regex}/ }
              end
            }.new).search('.search_price')
            sale_price = get_original_price(node)
            price = self.get_price(node)
            status = (node.empty? ? :bad_request : self.status(price))
            prices[curr] = { :price => (status == :ok ? Money.new(price, curr) : nil), :status => status, :type => category, :original_price => (!sale_price.nil? ? Money.new(sale_price, curr) : nil) }
          end
        end
        prices
      end
      
      def update_everything(currency = nil, display = true)
        #combine the two hashes
        g =   self.update_all_games(currency, display)
        p =   self.update_all_packs(currency, display)
        dlc = self.update_all_dlc(currency, display)
        n = Hash.new
        g.each    {|app_id, v| v.each {|game| n[app_id] = Array.new if !n[app_id]; n[app_id] << game }}
        p.each    {|app_id, v| v.each {|game| n[app_id] = Array.new if !n[app_id]; n[app_id] << game }}
        dlc.each  {|app_id, v| v.each {|game| n[app_id] = Array.new if !n[app_id]; n[app_id] << game }}
        n
      end
      
      def update_all_games(currency = nil, display = true)
        self.update_all(CATEGORIES[:game], currency, display)
      end

      def update_all_dlc(currency = nil, display = true)
        self.update_all(CATEGORIES[:dlc], currency, display)
      end

      
      def update_all_packs(currency = nil, display = true)
        self.update_all(CATEGORIES[:pack], currency, display)
      end
      
      # display stolen from https://github.com/spezifanta/SteamCalculator-Scripts/blob/master/getGames
      def update_all(category, currency = nil, display = true)
        games = Hash.new
      
        @countries = self.currency(currency)
      
        @countries.each do |curr, country|
          doc = attempt(2, 2) {
            Nokogiri::HTML(open(URI.encode("http://store.steampowered.com/search/results?sort_by=Name&sort_order=ASC&category1=#{category}&cc=#{country}&v6=1&page=1")))
          }
          next if !doc.search('.search_pagination_left')
          gamesPerPage, totalGames = doc.search('.search_pagination_left')[0].text.match(/showing\s\d+\s-\s(\d+)\sof\s(\d+)/m).captures

          totalPages = (totalGames.to_f / gamesPerPage.to_f).ceil

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
              url = game.attr('href').match(/(.*store\.steampowered\.com\/(app|sub)\/([\d]+)\/)/)
              # for things like /sale/
              if !url then
                games[game.attr('href')] = Array.new if !games[game.attr('href')]
                games[game.attr('href')] << { :status => :bad_request, :game => nil}
              else
                link, type, app_id = url.captures
                
                #remove retail price and put sale price
                original_price = self.get_original_price(game.search('.search_price'))
                price = self.get_price(game.search('.search_price'))
                date = game.search('.search_released').text
                name = game.search('h4').text
                logo = game.search('.search_capsule img').attr('src').value

                print "|% 8s |" % app_id + "% 8.2f |" % (price.to_f / 100) + "% 14s |" % date if display
                printf " %s%" + (43 - name[0,43].length).to_s + "s\n", name[0,42], " " if display
                status = self.status(price)
                game = SteamPrices::Game.new(name, app_id, link, logo, date, (status == :ok ? Money.new(price, curr) : nil), (!original_price.nil? ? Money.new(original_price, curr) : nil))
                
                games[app_id.to_i] = Array.new if !games[app_id.to_i]
                games[app_id.to_i] << { :game => game, :status => status, :type => category }
              end
            end

            printf "+---------+---------+---------------+--------------------------------------------\n\n" if display
            #grab the next page only if we're not on the last page
            doc = nil
            doc = attempt(3, 10) {
              Nokogiri::HTML(open(URI.encode("http://store.steampowered.com/search/results?sort_by=Name&sort_order=ASC&category1=#{category}&cc=#{country}&v6=1&page=#{i+1}"))) if i != totalPages
            }
          end
          
          # check if there are any special cases
          EXCEPTIONS.each do |app_id, v|
            if games.has_key? app_id then
              games[app_id].each do |g|
                price = Money.new(v, currency)                
                g[:game].price = price
                g[:game].original_price = price
              end
            end
          end
          
        end
        games      
      end
    end
    

 end
end                      