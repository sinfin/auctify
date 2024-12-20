# Change Log
All notable changes to this project will be documented in this file.

### 2024-11-15
- added `sale_counts_by_state` metric to Yabeda
- removed `yabeda-prometheus` gem dependency (now only `yabeda` is required).Other yabeda gems should be in main app.
## version 1.1.5
### 2023-09-05
- make difference between confirm of "Do not confirm bids for this auction" and "I agree with auction terms"

## version 1.1.4
### 2022-06-07
- added Yabeda-prometheus gem for exposing some metrics to scrape from Prometheus. See lib/yabeda_config.rb


## version 1.1.3
### 2022-04-19
- exposed `auction.minimal_bid_increase_amount_at(price)`

## version 1.1.0
### 2022-01-21
#### BREAKING
- `Auctify::BiddingCloserJob` is no longer enqueued on `start_sale` or requeued itself when auction end is in future.
   All is handled by `Auctify::EnsureAuctionsClosingJob` which should be run (by Your app) regulary in periods equals at least half of `Auctify.configuration.auction_prolonging_limit_in_seconds`.
   `Auctify::EnsureAuctionsClosingJob` look forward to future (in lenght of `auction_prolonging_limit_in_seconds`) and setup closing jobs for all auctions ending before that point.
   So each auction should have at least 2 enqueued closing job. Dont forget to run at start of Your app (just for sure).

## version 1.0.3
### 2021-09-17
#### BREAKING
- renamed `Auctify.configuration.auction_prolonging_limit` to `Auctify.configuration.auction_prolonging_limit_in_seconds` (to be more descriptive)
- added ability to set auction prolonging limit for sale pack. Time is taken from `sales_pack.auction_prolonging_limit_in_seconds`, or from `Auctify.configuration.auction_prolonging_limit_in_seconds`


## version 1.0.2
### 2021-09-08
- added `with_advisory_lock` block when closing of auction (and gem `with_advisory_lock`)

