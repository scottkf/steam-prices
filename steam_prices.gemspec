# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "steam/version"

Gem::Specification.new do |s|
  s.name     = "steamprices"
  s.version  = SteamPrices::VERSION
  s.platform = Gem::Platform::RUBY
  s.authors  = ["scott tesoriere"]
  s.email    = ["scott@tesoriere.com"]
  s.homepage = "http://github.com/scottkf/steam_prices"
  s.summary  = "Prices for stream."


  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  s.add_development_dependency "rspec", ">= 2.0.0.beta.12"
  s.add_development_dependency "nokogiri"
  s.add_development_dependency "money"
  s.add_development_dependency "open-uri"
end