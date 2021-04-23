# frozen_string_literal: true

module Auctify
  module AuctionHelpers
    def bid_for(bidder, price, max_price = nil)
      b_reg = registrations[bidder]
      Auctify::Bid.new(registration: b_reg, price: price, max_price: max_price)
    end

    def allow_bids_for(users, auction)
      @registrations = {}
      users.each do |user|
        @registrations[user] = auction.bidder_registrations.detect { |r| r.bidder == user }
      end
    end
  end
end
