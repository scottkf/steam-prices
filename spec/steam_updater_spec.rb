require 'spec_helper'

def find_game(games, currency, app_id, category = 998)
  games[app_id].each do |game|
    return game if (game[:game].price == nil || game[:game].price.currency.iso_code.upcase == currency.upcase) && game[:game].category == category
  end
  return nil
  
end

describe SteamPrices::Updater do

  before(:each) do
    URI.stub!(:encode)
  end
  
  context "pagination", :page => true do
    it "should correctly figure out and grab all the entries" do
      URI.should_receive(:encode).exactly(1).times.and_return(File.dirname(__FILE__) + '/support/page1.html')      
      URI.should_receive(:encode).exactly(1).times.and_return(File.dirname(__FILE__) + '/support/page2.html')      
      games = SteamPrices::Game.update_all_packs('usd', true)
    end
  end
  
  context "packs", :packs => true do
    before(:each) do
      # it says there are 5 pages
      URI.should_receive(:encode).exactly(1).times.and_return(File.dirname(__FILE__) + '/support/packs.html')
    end


    it "should not find any duplicates" do
      games = SteamPrices::Game.update_all_packs('usd', false)
      games.each do |k,v|
        v.collect { |g| g[:game].category if g[:game].category == SteamPrices::Updater::PACK }.size.should == 1
        v.collect { |g| g[:game].category if g[:game].category == SteamPrices::Updater::GAME }.size.should == 1
      end
    end

    it "should be able to tell whether it's a pack or a game" do
      games = SteamPrices::Game.update_all_packs('usd', false)
      find_game(games, 'usd', 6433, 996)[:type].should == SteamPrices::Updater::PACK
    end


    it "should be able to scrape steam and give a bunch of prices for a pack" do
      games = SteamPrices::Game.update_all_packs('usd', false)
      games.size.should == 25
      find_game(games, 'usd', 6433, 996)[:game].price.should == 39.99
    end
    
    it "should be able to find a single pack" do
      g = SteamPrices::Game.new('1C Action Collection', 6433, 'http://store.steampowered.com/sub/6433/?snr=1_7_7_230_150_1')
      g.update('usd')['usd'][:price].should == 39.99
    end
  end
  
  it "should be able to update EVERYTHING (usd)", :everything => true do
    URI.should_receive(:encode).exactly(5).times.and_return(File.dirname(__FILE__) + '/support/us.html')
    URI.should_receive(:encode).exactly(1).times.and_return(File.dirname(__FILE__) + '/support/packs.html')
    games = SteamPrices::Game.update_everything('usd', false)
    games.size.should == 25+18
    #pack
    find_game(games, 'usd', 6433, 996)[:game].price.to_f.should == 39.99
    find_game(games, 'usd', 6433, 996)[:status].should == :ok
    
    find_game(games, 'usd', 15540, 998)[:game].price.to_f.should == 8.99
    find_game(games, 'usd', 15540, 998)[:status].should == :ok
    #game
    find_game(games, 'usd', 22350, 998)[:game].price.to_f.should == 49.99
    find_game(games, 'usd', 22350, 998)[:status].should == :ok
    
  end
  
  it "should be able to update EVERYTHING (gbp)", :gbp => true do
    URI.should_receive(:encode).exactly(1).times.and_return(File.dirname(__FILE__) + '/support/uk.html')
    URI.should_receive(:encode).exactly(1).times.and_return(File.dirname(__FILE__) + '/support/packs.html')
    games = SteamPrices::Game.update_everything('gbp', true)
    # because thisis the total of theapp ids
    games.size.should == 25+25-1
    #pack
    find_game(games, 'gbp', 15540, 998)[:game].price.to_f.should == 5.99
    find_game(games, 'gbp', 15540, 998)[:status].should == :ok
    #game
    find_game(games, 'gbp', 12520, 998)[:game].price.to_f.should == 5.99
    find_game(games, 'gbp', 12520, 998)[:status].should == :ok
    
  end
  
  it "should be able to tell whether it's a pack or a game" do
    URI.should_receive(:encode).exactly(1).times.and_return(File.dirname(__FILE__) + '/support/uk.html')
    URI.should_receive(:encode).exactly(1).times.and_return(File.dirname(__FILE__) + '/support/packs.html')
    games = SteamPrices::Game.update_everything('gbp', true)
    find_game(games, 'gbp', 6433, 998)[:type].should == SteamPrices::Updater::GAME
    find_game(games, 'gbp', 6433, 996)[:type].should == SteamPrices::Updater::PACK
  end
  
  context "all prices" do

    before(:each) do
      # it says there are 5 pages
      URI.should_receive(:encode).exactly(5).times.and_return(File.dirname(__FILE__) + '/support/us.html')
      @games = SteamPrices::Game.update_all_games('usd', false)
    end

    it "should be able to scrape steam and give a bunch of prices" do
      @games.size.should == 19
    end  
  

  
  
  
    context "exceptions" do
      it "should be able to handle games like lost coast, which are part of a pack only and list the pack price" do
        find_game(@games, 'usd', 340, 998)[:game].price.should == 0.00
        find_game(@games, 'usd', 340, 998)[:game].original_price.should == 0.00
        find_game(@games, 'usd', 340, 998)[:game].price.class.name.should == "Money"
      end
  
      it "should find games with a sale price" do
        find_game(@games, 'usd', 39170, 998)[:game].price.should == 44.99
        find_game(@games, 'usd', 39170, 998)[:game].original_price.should == 49.99        
      end
      
      it "should have an ok status if the price is ok" do
        find_game(@games, 'usd', 22350, 998)[:game].price.should == 49.99
        find_game(@games, 'usd', 22350, 998)[:status].should == :ok
      end
      
      it "should have a not found status if the price is empty but the url is found (preorder)" do
        find_game(@games, 'usd', 55150, 998)[:game].price.should == nil
        find_game(@games, 'usd', 55150, 998)[:status].should == :not_found
      end




      it "should have a bad request status if the url is invalid or some other crazy error" do
        @games['http://store.steampowered.com/sale/magic2011?snr=1_7_7_230_150_27'][0][:status].should == :bad_request
      end

    end
  
    
  end
  
  
  
  context "a single price", :single => true do
    before(:each) do
      URI.should_receive(:encode).and_return(File.dirname(__FILE__) + '/support/us.html')
    end


    it "should find games with a sale price" do
      g = SteamPrices::Game.new('somename', 39170)
      p = g.update('usd')['usd']
      p[:original_price].should == 49.99
      p[:price].should == 44.99
    end


    it "should be able to return a status if it was ok" do
      g = SteamPrices::Game.new('brink', 22350)
      p = g.update('usd')['usd']
      p[:price].should == 49.99      
      p[:status].should == :ok
    end

    it "should be able to return a price even if the price was 0" do
      g = SteamPrices::Game.new('brink', 10650)
      p = g.update('usd')['usd']
      p[:price].should == 0.00      
      p[:status].should == :ok      
    end



    it "should be able to return not found if it wasn't ok" do
      g = SteamPrices::Game.new('Warhammer 40,000: Space Marine', 55150)
      p = g.update('usd')['usd']
      p[:price].should == nil 
      p[:status].should == :not_found
    end

    it "should be able to get confused if something went crazy or wasn't there" do
      g = SteamPrices::Game.new('awdwad', 21231232350)
      g.update('usd')['usd'][:status].should == :bad_request   
    end

    it "should be able to find a single game and update it's price (instance)" do
      g = SteamPrices::Game.new('brink', 22350)
      g.update('usd')['usd'][:price].should == 49.99

    end

    it "should be able to find a single game and update it's price (class)" do
      prices = SteamPrices::Game.update_one_game('brink', 22350, 'usd')
      prices['usd'][:price].should == 49.99
    end    
  end

end