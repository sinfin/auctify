# Change Log
All notable changes to this project will be documented in this file.

## version 1.0.3
### 2021-09-17
#### BREAKING
- renamed `Auctify.configuration.auction_prolonging_limit` to `Auctify.configuration.auction_prolonging_limit_in_seconds` (to be more descriptive)
- added ability to set auction prolonging limit for sale pack. Time is taken from `sales_pack.auction_prolonging_limit_in_seconds`, or from `Auctify.configuration.auction_prolonging_limit_in_seconds`


## version 1.0.2
### 2021-09-08
- added `with_advisory_lock` block when closing of auction (and gem `with_advisory_lock`)

