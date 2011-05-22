require 'spec_helper'

describe SteamPrices::Updater do

  before(:each) do
    URI.stub!(:encode)
  end
  context "all prices" do

    it "should be able to scrape steam and give a bunch of prices" do
      URI.should_receive(:encode).exactly(5).times.and_return(File.dirname(__FILE__) + '/support/us.html')
      games = SteamPrices::Game.update_all('usd')
      # the pages are set to 5 in the example, and there are 19 items on the page
      5.times do |i|
        games[i*19].price.should == 9.99
      end
      games.size.should == 95
    end  
    
  end
  
  context "a single price" do
    before(:each) do
      URI.should_receive(:encode).and_return(File.dirname(__FILE__) + '/support/us.html')

    end

    it "should be able to find a single game and update it's price (instance)" do
      g = SteamPrices::Game.new('brink', 22350)
      g.update('usd')['usd'].should == 49.99

    end

    it "should be able to find a single game and update it's price (class)" do
      prices = SteamPrices::Game.update_one('brink', 22350, 'usd')
      prices['usd'].should == 49.99
    end    
  end

end