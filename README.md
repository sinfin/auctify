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





