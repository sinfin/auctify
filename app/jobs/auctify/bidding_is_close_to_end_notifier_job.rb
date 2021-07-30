# frozen_string_literal: true

module Auctify
  class BiddingIsCloseToEndNotifierJob < Auctify::ApplicationJob
    queue_as :default

    def perform(auction_id:)
      return if auction_id.blank?
      return if Auctify.configuration.when_to_notify_bidders_before_end_of_bidding.nil?

      begin
        auction = Auctify::Sale::Auction.find(auction_id)
      rescue ActiveRecord::RecordNotFound
        return
      end

      notify_time = auction.bidding_is_close_to_end_notification_time

      return unless auction.open_for_bids?

      if notify_time <= Time.current
        auction.before_bidding_is_close_to_end
      else
        self.class.set(wait_until: notify_time)
                  .perform_later(auction_id: auction.id)
      end
    end
  end
end
