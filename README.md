# Auctify
Rails engine for auctions of items. Can be used on any ActiveRecord models.

## Objects
- `:item` - object/model, which should be auctioned (from `main_app`)
- `:user` - source for `seller`, `owner`, `buyer` and `bidder` (from `main_app`)
- `sale` - sale of `:item`; can be direct `retail`, by `auction` or some other type
- `auction` for one `:item` (it is [Forward auction](https://en.wikipedia.org/wiki/Forward_auction)) (v češtině "Položka aukce")
- `seller` - person/company which sells `:item` in specific `sale`
- `bidder` - registered person/user allowed to bid in specific `auction`
- `buyer` - person/company which buys `:item` in specific `sale` ( eg. winner of auction)
- `bid` - one bid of one `bidder` in `auction`
- `sales_pack` - pack of sales(auctions), mostly time framed, Can have physical location or be online. (v češtině "Aukce")
- `auctioneer` - (needed?) company organizing `auction`

## Relations
- `:item` 1 : 0-N `sale`, (sale time periods cannot overlap)
- `:item` N : 1 `owner` (can change in time)
- `sale` N : 1 `seller`
- `sale` N : 1 `buyer`
- `sale::auction` 1 : N `bidders` (trough `bidder_registrations`) 1 : N `bids`
- `sales_pack` 0-1 : N `sales`  (`sales_pack` is optional for `sale`)
- `auction` N : 1 `auctioneer` (?)


## Classes
###  Sales
 - `Sale::Auction` - full body auction of one item for many registered  buyer (as bidders)
 - `Sale::Retail` - direct sale of item to one buyer

## TODO
- generator to copy auction's views to main app (so they can be modified) (engine checks main_app views first)



## Notices
`sale belongs_to item`  polymorphic , STI typed
`sale belongs_to seller`  polymorphic
`sale belongs_to buyer`  polymorphic
`auction has_many bidder_registrations` (?bidders?)
`bidder_registration belongs buyer` polymorphic

If `item.owner` exists, it is used as `auction.seller` (or Select from all aucitfied sellers)

## Features required

- if bidder adds bid in `:prolonging_limit` minutes before auction ends, end time is extended for `bid.time + prolonging_limit` (so auction end when there are no bids in last `:prolonging_limit` minutes)
- for each auction, there can be set of rules for minimal `bid` according to current `auctioned_price` (default can be `(1..Infinity) => 1`)
  real example
  ```
  minimal_bids = {
    (0...5_000) => 100,
    (5_000...20_000) => 500,
    (20_000...100_000) => 1_000,
    (100_000...500_000) => 5_000,
    (500_000...1_000_000) => 10_000,
    (1_000_000...2_000_000) => 50_000,
    (2_000_000..) => 100_000
    }
  ```
- first bid do not increase `auctioned_price` it stays on `base_price`
- bidder cannot "overbid" themselves (no following bids from same bidder)
- auctioneer can define format of auction numbers (eg. "YY#####") and sales_pack numbers
- there should be ability to follow `auction` (notification before end) or `item.author` (new item in auction)
- item can have category and user can select auction by categories.
- SalePack can be `(un)published /public`
- SalePack can be `open (adding items , bidding)/ closed(bidding ended)`
- auctioneer_commision_from_buyer is in % and adds to sold_price in checkout
- auction have `start_time` and `end_time`
- auction can be `highlighted` for cover pages
- auction stores all bids history even those cancelled by admin
- there should be two types of bid
   - one with maximal price (amount =>  maximal bid price; placed in small bids as needed), system will increase bid automagicaly unless it reaches maximum
   - second direct bid (amount => bid price; immediattely placed)
- sales numbering: YY#### (210001, 210002, …, 259999)





## Usage
In `ActiveRecord` model use class method `auctify_as` with params `:buyer`,`:seller`, `:item`.
```ruby
class User < ApplicationRecord
  auctify_as :buyer, :seller # this will add method like `sales`, `puchases` ....
end

class Painting < ApplicationRecord
  auctify_as :item # this will add method like `sales` ....
end
```
`Auctify` expects that auctifyied model instances responds to `to_label` and `:item` to reponds to `owner` (which should lead to object auctified as `:seller`)!

## Installation
  1. ### Add gem
      Add this line to your application's Gemfile:

      ```ruby
      gem 'auctify'
      ```

      And then execute:
      ```bash
      $ bundle
      ```

      Or install it yourself as:
      ```bash
      $ gem install auctify
      ```

  2. ### Auctify classes
      ```ruby
      class User < ApplicationRecord
        auctify_as :buyer, :seller # this will add method like `sales`, `puchases` ....
      end

      class Painting < ApplicationRecord
        auctify_as :item # this will add method like `sales` ....
      end
      ```

  3. ### Configure
      - optional
      ```ruby
        Auctify.configure do |config|
          config.autoregister_as_bidders_all_instances_of_classes = ["User"] # default is []
          config.auction_prolonging_limit = 10.minutes # default is 1.minute
          config.auctioneer_commission_in_percent = 10 # so buyer will pay: auction.current_price * ((100 + 10)/100)
          config.autofinish_auction_after_bidding = true # after `auction.close_bidding!` immediatelly proces result to `auction.sold_in_auction!` or `auction.not_sold_in_auction!`; default false
          config.when_to_notify_bidders_before_end_of_bidding = 30.minutes # default `nil` => no notifying
          config.restrict_overbidding_yourself_to_max_price_increasing = false # default is `true` so only bids with `max_price` can be applied if You are winner.
        end
      ```

      If model autified as `:buyer` responds to `:bidding_allowed?` , check is done before each `auction.bid!`. Also if `buyer.bidding_allowed? => true` , registration to auction is created on first bid.
  4. ### Callbacks
    For available auction callback methods to override see `app/concerns/auctify/sale/auction_callbacks.rb`


  5. ### Use directly
      ```ruby
        banksy = User.find_by(nickname: "Banksy")
        bidder1 = User.find_by(nickname: "Bidder1")
        bidder2 = User.find_by(nickname: "Bidder2")
        piece = Painting.find_by(title: "Love is in the bin")

        piece.owner == banksy # => (not actually) :true

        auction = banksy.offer_to_sale!(piece, { in: :auction, price: 100 })

        auction.offered? # => :true
        auction.item == piece # => :true
        auction.seller == banksy # => :true
        auction.offered_price # => 100.0

        banksy.sales # => [auction]
        banksy.auction_sales # => [auction]
        banksy.retail_sales # => []

        pieces.sales # => [auction]

        auction.bidder_registrations # => []   unless config.autoregister_as_bidders_all_instances_of_classes is set
        auction.bidder_registrations.create(bidder: bidder1) # => error, not allowed ("Aukce aktuálně nepovoluje nové registrace")

        auction.accept_offer!

        b1_reg = auction.bidder_registrations.create(bidder: bidder1)
        b2_reg = auction.bidder_registrations.create(bidder: bidder2)

        auction.bidder_registrations.size # => 2
        auction.current_price # => nil

        auction.start_sale!
        auction.current_price # => 100.0

        aucion.bid!(Auctify::Bid.new(registration: b1_reg, price: nil, max_price: 150))
        # auction.bid_appended! is called after succesfull bid, You can override it
        # auction.bid_not_appended!(errors) is called after unsuccesfull bid, You can override it

        auction.current_price # => 100.0
        auction.bidding_result.winner # => bidder1
        auction.bidding_result.current_price # => 100.0
        auction.bidding_result.current_minimal_bid # => 101.0    `auction.bid_steps_ladder` is empty, we increasing by 1

        aucion.bid!(Auctify::Bid.new(registration: b2_reg, price: 145, max_price: nil))
        # some auto bidding is done
        auction.current_price # => 146.0
        auction.bidding_result.winner # => bidder1
        auction.bidding_result.current_price # => 146.0
        auction.bidding_result.current_minimal_bid # => 147.0
        auction.winner # => nil

        aucion.bid!(Auctify::Bid.new(registration: b2_reg, price: 149, max_price: 155))
        # some auto bidding is done
        auction.current_price # => 151.0
        auction.bidding_result.winner # => bidder2
        auction.bidding_result.current_price # => 151.0
        auction.bidding_result.current_minimal_bid # => 152.0

        auction.close_bidding!
        auction.bidding_ended? # => true
        auction.buyer # => nil
        auction.winner # => bidder2

        auction.sold_in_auction!(buyer: bidder2, price: 149, sold_at: currently_ends_at)  # it is verified against bids!

        auction.auctioned_successfully? # => true
        auction.buyer # => bidder2

        # when all negotiations went well
        auction.sell!

        auction.sold? # => true
      ```

      Look into tests `test/models/auctify/sale/auction_bidding_test.rb` and `test/services/auctify/bid_appender_test.rb` for more info about bidding process.

      To protect accidential deletions, many associations are binded with `dependent: restrict_with_error`. Correct order ofdeletion is `bids` => `sales` => `sales_packs`.



## Contributing
Contribution directions go here.

## License
The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).


