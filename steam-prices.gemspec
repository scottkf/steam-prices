$LOAD_PATH << File.join(File.dirname(__FILE__), 'lib')
require "steam_prices/version"

Gem::Specification.new do |s|
  s.name     = %q{steam-prices}
  s.version  = SteamPrices::VERSION
  s.platform = Gem::Platform::RUBY
  s.authors  = ["scott tesoriere"]
  s.email    = %q{scott@tesoriere.com}
  s.homepage = %q{http://github.com/scottkf/steam_prices}
  s.summary  = %q{Prices for steam.}


  s.files        = Dir['[A-Z]*', 'lib/**/*.rb', 'spec/**/*.rb', 'features/**/*', 'rails/**/*']
  s.require_path = 'lib'
  s.test_files   = Dir['spec/**/*_spec.rb', 'features/**/*']

  s.add_development_dependency "rspec", ">= 2.0.0.beta.12"
  s.add_development_dependency "nokogiri"
  s.add_development_dependency "money"
  s.add_development_dependency "open-uri"
  
  s.platform = Gem::Platform::RUBY
  s.rubygems_version = %q{1.2.0}
end