# frozen_string_literal: true

require "test_helper"

module Auctify
  module Sale
    class AuctionSetupTest < ActiveSupport::TestCase
      attr_reader :auction

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
    end
  end
end
