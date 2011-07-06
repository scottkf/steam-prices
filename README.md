## changelog

**v0.2.0**

- resolved connection errors, retries a few times

**v0.1.9**

- floating point error wouldn't grab all pages

**v0.1.8**

- issues with nokogiri
- saves sale prices in :original_price

**v0.1.7**

- dealing with free games
- limited countries
- trailing slash removed
- should update all prices if nil is passed
- special exception wasn't of Money class

**v0.1.6**

- forgot to handle a case for retribution, where it would update a single one

**v0.1.5**

- refactoring

**v0.1.4**

- can update packs
- handles special exceptions, like lost coast

**v0.1.3** 

- fixed problem when dealing with sale prices

**v0.1.2**

- floating point error

**v0.1.1**

- dealing with improper urls (for sales, etc), returns a nil object if it comes across one