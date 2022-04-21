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

      if Time.current < auction.currently_ends_at
        Rails.logger.info("Too soon for closing of auction #{auction_label(auction)}.")
      else
        Rails.logger.info("Closing auction #{auction_label(auction)} NOW!")
        Auctify::Sale::Auction.with_advisory_lock("closing_auction_#{auction_id}") do
          # can wait unitl other BCJob release lock and than continue!
          auction.close_bidding! if auction.reload.in_sale?
        end
      end
    end
  end
end
