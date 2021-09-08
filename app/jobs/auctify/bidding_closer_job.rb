# frozen_string_literal: true

module Auctify
  class BiddingCloserJob < Auctify::ApplicationJob
    queue_as :default

    def perform(auction_id:)
      return if auction_id.blank?
      begin
        auction = Auctify::Sale::Auction.find(auction_id)
      rescue ActiveRecord::RecordNotFound
        return
      end

      if auction.currently_ends_at <= Time.current
        Auctify::Sale::Auction.with_advisory_lock("closing_auction_#{auction_id}") do
          auction.close_bidding! if auction.in_sale?
        end
      else
        self.class.set(wait_until: auction.currently_ends_at)
                  .perform_later(auction_id: auction.id)
      end
    end
  end
end
