module SteamPrices
  class Updater
    

    attr_reader :countries

    def initialize(currency = nil)
      self.currency(currency)
    end


    def currency(c)
      @countries = (c.nil? && SteamPrices::Country.currencies) || { c => SteamPrices::Country.get_country(c) }
    end

    def update(currency = nil, app_id = nil, app_name = nil)
      games = Array.new
      
      self.currency(currency) if !currency.nil?
      
      @countries.each do |curr, country|
        doc = Nokogiri::HTML(open(URI.encode("http://store.steampowered.com/search/results?sort_by=Name&sort_order=ASC&category1=998&cc=#{country}&v6=1&page=1")))
        gamesPerPage, totalGames = doc.search('.search_pagination_left')[0].text.match(/showing\s\d+\s-\s(\d+)\sof\s(\d+)/m).captures

        totalPages = (totalGames.to_i / gamesPerPage.to_i).ceil

        doc.search('.search_result_row').each do |game|
          link, app_id = game.attr('href').match(/(.*store\.steampowered\.com\/app\/([\d]+)\/)/).captures
          price = game.search('.search_price').text.gsub(/[\W_]/, '').to_i
          date = game.search('.search_released').text
          name = game.search('h4').text
          logo = game.search('.search_capsule img').attr('src').value

          games << SteamPrices::Game.new(name, app_id, link, logo, date, Money.new(price, curr))

        end
      end
      games      
    end
    
    
    def game(name, app_id, currency = nil)      
      prices = Hash.new
      
      self.currency(currency) if !currency.nil?
      
      @countries.each do |curr, country|
        doc = Nokogiri::HTML(open(URI.encode("http://store.steampowered.com/search/results?sort_by=Name&sort_order=ASC&category1=998&cc=#{country}&v6=1&page=1&term=#{name}")))
        price = doc.xpath('.//a[regex(., "/store\.steampowered\.com\/app\/' + app_id.to_s + '/")]', Class.new {
          def regex node_set, regex
            node_set.find_all { |node| node['href'] =~ /#{regex}/ }
          end
        }.new).search('.search_price').text.gsub(/[\W_]/, '').to_i
        prices[app_id] = Money.new(price, curr)
      end
      prices
    end
    
 end
end