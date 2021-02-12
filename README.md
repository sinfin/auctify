# Auctify
Rails engine for auctions of items

## Objects
- `:item` - object/model, which should be auctioned
- `auction` for one `:item` (it is [Forward auction](https://en.wikipedia.org/wiki/Forward_auction))
- `seller` - person/company which owns `:item`
- `bidder` - registered person/user allowed to bid in specific `auction`
- `bid` - one bid of one `bidder` in `auction`
- `auction_event` - pack of auctions, mostly time framed, Can have physical location or be online.
- `auctioneer` - (needed?) company organizing `auction`

## Relations
- `:item` N : 0-1 `auction` (auctions time periods cannot overlap)
- `:item` N : 1 `seller`
- `auction` M : N `bidders` 1 : N `bids`
- `auction_event` 0-1 : N `auctions`  (`auction_event` is optional for `auction`)
- `auction` N : 1 `auctioneer`




## TODO
- generator to copy auction's views to main app (so they can be modified) (engine checks main_app views first)



## Notices
`auction belongs_to item`  polymorphic
`auction belongs_to seller`  polymorphic
`auction has_many bidder_links` (?bidders?)
`bidder_link belongs bidder` polymorphic

If `item.owner` exists, it is used as `auction.seller` (or Select from all aucitfied sellers)

Concerns
- `auctified_as: :seller, :bidder` (User, Folio::User)
- `auctified_as: :item` (Thing, Art, Car)


## Usage
How to use my plugin.

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
