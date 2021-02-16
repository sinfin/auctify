# Auctify
Rails engine for auctions of items. Can be used on any ActiveRecord models.

## Objects
- `:item` - object/model, which should be auctioned (from `main_app`)
- `:user` - source for `seller`, `owner`, `buyer` and `bidder` (from `main_app`)
- `sale` - sale of `:item`; can be direct `retail`, by `auction` or some other way
- `auction` for one `:item` (it is [Forward auction](https://en.wikipedia.org/wiki/Forward_auction))
- `seller` - person/company which sells `:item` in specific `sale`
- `bidder` - registered person/user allowed to bid in specific `auction`
- `buyer` - person/company which buys `:item` in specific `sale` ( eg. winner of auction)
- `bid` - one bid of one `bidder` in `auction`
- `auction_event` - pack of auctions, mostly time framed, Can have physical location or be online.
- `auctioneer` - (needed?) company organizing `auction`

## Relations
- `:item` 1 : 0-N `sale`, (sale time periods cannot overlap)
- `:item` N : 1 `owner` (can change in time)
- `sale` N : 1 `seller`
- `sale` N : 1 `buyer`
- `sale::auction` 1 : N `bidders` (trough `auction_registration`) 1 : N `bids`
- `auction_event` 0-1 : N `auctions`  (`auction_event` is optional for `auction`)
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
`auction has_many bidder_links` (?bidders?)
`bidder_link belongs bidder` polymorphic

If `item.owner` exists, it is used as `auction.seller` (or Select from all aucitfied sellers)

Concerns
- `auctified_as: :seller, :buyer, :bidder` (User, Folio::User)
- `auctified_as: :item` (Thing, Art, Car)


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


