require 'spec_helper'

describe SteamPrices::Game do

  it "should be able to have an app id, app name, logo, and store link" do
    g = SteamPrices::Game.new('brink', 31314, '', '', '', Money.new(1499, 'USD'), Money.new(1299, 'USD'))
    g.app_name.should == 'brink'
    g.app_id.should == 31314
  end

  it "should have a valid price of the money class" do
    lambda { g = SteamPrices::Game.new('brink', 31314, '', '', '', '') }.should raise_error
    g = SteamPrices::Game.new('brink', 31314, '', '', '', Money.new(1499, 'USD'), Money.new(1299, 'USD'))
    g.price.should == 14.99
    g.original_price.should == 12.99
  end


end