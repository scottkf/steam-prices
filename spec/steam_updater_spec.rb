require 'spec_helper'

describe SteamPrices::Updater do

  before(:each) do
    URI.stub!(:encode)
  end
  
  
  context "packs", :packs => true do
    before(:each) do
      # it says there are 5 pages
      URI.should_receive(:encode).exactly(1).times.and_return(File.dirname(__FILE__) + '/support/packs.html')
    end

    it "should be able to scrape steam and give a bunch of prices for a pack" do
      games = SteamPrices::Game.update_all_packs('usd', false)
      games.size.should == 25
      games[6433]['usd'][:game].price.should == 39.99
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
    games.size.should == 25+19
    #pack
    games[6433]['usd'][:game].price.should == 39.99
    games[6433]['usd'][:status].should == :ok
    
    games[15540]['usd'][:status].should == :ok
    games[15540]['usd'][:game].price.should == 8.99
    #game
    games[22350]['usd'][:game].price.should == 49.99
    games[22350]['usd'][:status].should == :ok
    
  end
  
  it "should be able to update EVERYTHING (gbp)", :gbp => true do
    URI.should_receive(:encode).exactly(1).times.and_return(File.dirname(__FILE__) + '/support/uk.html')
    URI.should_receive(:encode).exactly(1).times.and_return(File.dirname(__FILE__) + '/support/packs.html')
    games = SteamPrices::Game.update_everything('gbp', true)
    games.size.should == 25+25
    #pack
    # puts games[15540]['gbp'][:game].price
    games[15540]['gbp'][:game].price.should == 6.99
    games[15540]['gbp'][:status].should == :ok
    #game
    games[12520]['gbp'][:game].price.should == 5.99
    games[12520]['gbp'][:status].should == :ok
    
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
        @games[340]['usd'][:game].price.should == 0.00
        @games[340]['usd'][:game].price.class.name.should == "Money"
      end
      
      it "should be able to handle games like warhammer retribution where it points to a different app id" do
        @games[56400]['usd'][:game].price.should == 29.99
      end
      
      it "should have an ok status if the price is ok" do
        @games[22350]['usd'][:game].price.should == 49.99
        @games[22350]['usd'][:status].should == :ok
      end
      
      it "should have a not found status if the price is empty but the url is found (preorder)" do
        @games[55150]['usd'][:game].price.should == nil
        @games[55150]['usd'][:status].should == :not_found
      end


      it "should have a bad request status if the url is invalid or some other crazy error" do
        @games['http://store.steampowered.com/sale/magic2011?snr=1_7_7_230_150_27']['usd'][:status].should == :bad_request
      end

    end
  
    
  end
  
  
  
  context "a single price", :single => true do
    before(:each) do
      URI.should_receive(:encode).and_return(File.dirname(__FILE__) + '/support/us.html')
    end


    it "should be able to return a status if it was ok" do
      g = SteamPrices::Game.new('brink', 22350)
      p = g.update('usd')['usd']
      p[:price].should == 49.99      
      p[:status].should == :ok
    end


    it "should be able to deal with a game like retribution where it redirects to an id", :ret => true do
      g = SteamPrices::Game.new('Warhammer® 40,000®: Dawn of War® II – Retribution™', 56400)
      p = g.update('usd')['usd']
      p[:price].should == 29.99
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