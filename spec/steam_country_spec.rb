require 'spec_helper'

describe SteamPrices::Country do

  context "currency from country" do
    it "should return a currency if I specify a valid country" do
      SteamPrices::Country.get_currency('us').should == 'usd'
    end

    it "should return nil if I specify an invalid country" do
      SteamPrices::Country.get_currency('la').should == nil  
    end    
  end


  context "country from currency" do
    it "should return a country if I specify a valid currency" do
     SteamPrices::Country.get_country('usd').should == 'us'
    end

    it "should return nil if I specify an invalid currency" do
      SteamPrices::Country.get_country('hello').should == nil  
    end    
  end


end