module SteamPrices
  class Country
    
    @currencies = {
      'usd'       => 'us',
      'gbp'       => 'uk',
      'aud'       => 'au',
      'eur'       => 'fr',

    class << self; attr_reader :currencies; end
    
    def initialize
    end
    
    def self.get_currency(country)
      return (country.length == 2 ? @currencies.index(country) : nil)
    end

    def self.get_country(currency)
      return (currency.length == 3 ? @currencies[currency] : nil)
    end
  end
end