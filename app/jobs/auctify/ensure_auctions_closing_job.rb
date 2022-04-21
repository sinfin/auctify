# frozen_string_literal: true

module Auctify
  class EnsureAuctionsClosingJob < ApplicationJob
    queue_as :critical

    def perform
      auctions = ::Auctify::Sale::Auction.in_sale
                                      .where("currently_ends_at <= ?", Time.current + checking_period_to_future)
      auctions.each do |auction|
        if auction.currently_ends_at <= Time.current
          Rails.logger.info("Queueing auction #{auction_label(auction)} for immediate close.")
          Auctify::BiddingCloserJob.perform_later(auction_id: auction.id)
        else
          Rails.logger.info("Delaying close of auction #{auction_label(auction)}.")
          Auctify::BiddingCloserJob.set(wait_until: auction.currently_ends_at).perform_later(auction_id: auction.id)
        end
      end
    end

    private
      def checking_period_to_future
        Auctify.configuration.auction_prolonging_limit_in_seconds || 5.minutes
      end
  end
end
