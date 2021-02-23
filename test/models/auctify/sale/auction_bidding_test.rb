# frozen_string_literal: true

require "test_helper"

module Auctify
  module Sale
    class AuctionBiddingTest < ActiveSupport::TestCase
      attr_reader :auction

      setup do
        @auction = auctify_sales(:eve_apple)
        @auction.accept_offer
        @auction.start_sale

        assert @auction.valid?, "auction is not valid! : #{@auction.errors.full_messages}"

        # bidders
      end

      test "can process bids" do
        skip
      end
    end
  end
end
