# frozen_string_literal: true

require "test_helper"

module Auctify
  module Sale
    class AuctionTest < ActiveSupport::TestCase
      attr_reader :auction
      include Auctify::AuctionHelpers

      test "have initial auctioneer_commission from config" do
        auction = Auctify::Sale::Auction.new
        assert_equal Auctify.configuration.auctioneer_commission_in_percent, auction.commission_in_percent
        assert auction.commission_in_percent.present?
      end

      test "currently_ends_at adapts according to ends_at" do
        ends_at = Time.current + 1.hour
        ends_at_new = ends_at + 1.day

        auction = Auctify::Sale::Auction.new(seller: users(:eve),
                                             item: things(:apple),
                                             offered_price: 123.4,
                                             ends_at: ends_at)
        assert_equal ends_at, auction.ends_at
        assert_nil auction.currently_ends_at

        auction.accept_offer

        assert_equal ends_at, auction.ends_at
        assert_nil auction.currently_ends_at

        auction.start_sale

        assert_equal ends_at, auction.ends_at
        assert_equal ends_at, auction.currently_ends_at

        auction.ends_at = ends_at_new

        assert_equal ends_at_new, auction.ends_at
        assert_equal ends_at_new, auction.currently_ends_at
      end

      test "recalculating can handle 'no_bids_left'" do
        auction = auctify_sales(:auction_in_progress)
        assert_equal 2, auction.applied_bids_count
        assert_not_equal auction.offered_price, auction.current_price

        auction.ordered_applied_bids.each do |bid|
          bid.cancel! # which calls recalculating
        end

        assert auction.reload.applied_bids_count.zero?
        assert auction.ordered_applied_bids.count.zero?
        assert_equal auction.offered_price, auction.current_price
      end
    end
  end
end
