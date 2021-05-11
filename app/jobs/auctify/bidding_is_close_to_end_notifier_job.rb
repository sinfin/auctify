# frozen_string_literal: true

module Auctify
  class BiddingIsCloseToEndNotifierJob < Auctify::ApplicationJob
    queue_as :default

    def perform(auction_id:)
      auction = Auctify::Sale::Auction.find(auction_id)
      notify_time = auction.ends_at - Auctify.configuration.when_to_notify_bidders_before_end_of_bidding

      for_auction_str = " for auction[#{auction.id}] ending at { orginal: #{auction.ends_at}, current: #{auction.currently_ends_at}}"

      if notify_time <= Time.current && auction.open_for_bids?
        puts("PUTS: running `auction.before_bidding_is_close_to_end` #{for_auction_str}")
        Rails.logger.info("LOGGER: running `auction.before_bidding_is_close_to_end` #{for_auction_str}")

        auction.before_bidding_is_close_to_end
      else
        puts("PUTS: setting new invocation to #{notify_time} #{for_auction_str}")
        Rails.logger.info("LOGGER: setting new invocation to #{notify_time} #{for_auction_str}")

        self.class.set(wait_until: notify_time)
                  .perform_later(auction_id: auction.id)
      end
    end
  end
end
