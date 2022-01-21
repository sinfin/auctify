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

      return if Time.current < auction.currently_ends_at

      Auctify::Sale::Auction.with_advisory_lock("closing_auction_#{auction_id}") do
        # can wait unitl other BCJob release lock and than continue!
        auction.close_bidding! if auction.reload.in_sale?
      end
    end
  end
end
