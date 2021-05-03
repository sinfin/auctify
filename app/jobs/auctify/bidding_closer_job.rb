# frozen_string_literal: true

module Auctify
  class BiddingCloserJob < Auctify::ApplicationJob
    queue_as :default

    def perform(auction_id:)
      auction = Auctify::Sale::Auction.find(auction_id)
      if auction.currently_ends_at <= Time.current
        auction.close_bidding! if auction.in_sale?
      else
        self.class.set(wait_until: auction.currently_ends_at)
                  .perform_later(auction_id: auction.id)
      end
    end
  end
end
