module SteamPrices
  module Updater
    


    def self.included(base)
      base.extend ClassMethods
    end
    
  


    module ClassMethods
      def currency(c)
        return (c.nil? && SteamPrices::Country.currencies) || { c => SteamPrices::Country.get_country(c) }
      end
    

      # update a single one
      def update_one(name, app_id, currency = nil)      
        prices = Hash.new

        @countries = self.currency(currency) if !currency.nil?

        @countries.each do |curr, country|
          doc = Nokogiri::HTML(open(URI.encode("http://store.steampowered.com/search/results?sort_by=Name&sort_order=ASC&category1=998&cc=#{country}&v6=1&page=1&term=#{name}")))
          price = doc.xpath('.//a[regex(., "/store\.steampowered\.com\/app\/' + app_id.to_s + '/")]', Class.new {
            def regex node_set, regex
              node_set.find_all { |node| node['href'] =~ /#{regex}/ }
            end
          }.new).search('.search_price').text.gsub(/[\W_]/, '').to_i
          prices[curr] = Money.new(price, curr)
        end
        prices
      end
      
      
      # display stolen from https://github.com/spezifanta/SteamCalculator-Scripts/blob/master/getGames
      def update_all(currency = nil, display = true)
        games = Array.new
      
        @countries = self.currency(currency) if !currency.nil?
      
        @countries.each do |curr, country|
          doc = Nokogiri::HTML(open(URI.encode("http://store.steampowered.com/search/results?sort_by=Name&sort_order=ASC&category1=998&cc=#{country}&v6=1&page=1")))
          gamesPerPage, totalGames = doc.search('.search_pagination_left')[0].text.match(/showing\s\d+\s-\s(\d+)\sof\s(\d+)/m).captures

          totalPages = (totalGames.to_i / gamesPerPage.to_i).ceil

          for i in 1..totalPages

            if display then
              printf "\n   Loading '#{country}', page %02d of %02d                                                \n", i, totalPages
              printf "   Entries % 5d - % 5d of %d                                                \n", ((i - 1) * gamesPerPage.to_i + 1), (i * gamesPerPage.to_i), totalGames
              printf "+---------+---------+---------------+--------------------------------------------\n"
              printf "|  AppID  |  Price  |    Release    |                 Game Title                 \n"
              printf "+---------+---------+---------------+--------------------------------------------\n"
            end
            
            doc.search('.search_result_row').each do |game|
              url = game.attr('href').match(/(.*store\.steampowered\.com\/app\/([\d]+)\/)/)
              if !url then
                games << nil
              else
                link, app_id = url.captures
                price = game.search('.search_price').text.gsub(/[\W_]/, '').to_f
                date = game.search('.search_released').text
                name = game.search('h4').text
                logo = game.search('.search_capsule img').attr('src').value

                print "|% 8s |" % app_id + "% 8.2f |" % (price / 100) + "% 14s |" % date if display
                printf " %s%" + (43 - name[0,43].length).to_s + "s\n", name[0,42], " " if display
                games << SteamPrices::Game.new(name, app_id, link, logo, date, Money.new(price, curr))
              end
            end

            printf "+---------+---------+---------------+--------------------------------------------\n\n" if display
            #grab the next page only if we're not on the last page
            doc = Nokogiri::HTML(open(URI.encode("http://store.steampowered.com/search/results?sort_by=Name&sort_order=ASC&category1=998&cc=#{country}&v6=1&page=#{i+1}"))) if i != totalPages

          end
          
        end
        games      
      end
    end
    

 end
end