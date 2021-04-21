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
- auctioneer_commission is in % and adds to sold_price in checkout
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
`Auctify` expects that auctifyied model instances responds to `to_label` !!

## Installation
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

## Contributing
Contribution directions go here.

## License
The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).


