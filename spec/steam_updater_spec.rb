require 'spec_helper'

describe SteamPrices::Updater do
  before(:each) do
    URI.stub!(:encode)
    URI.should_receive(:encode).and_return(File.dirname(__FILE__) + '/support/us.html')

  end

  it "should be able to scrape steam and give a bunch of prices" do
    games = SteamPrices::Game.update_all('usd')
    games.size.should == 19
    games.first.price.should == 9.99


  end  
  it "should be able to find a single game and update it's price" do
    g = SteamPrices::Game.new('brink', 22350)
    g.update('usd')['usd'].should == 49.99

  end
end