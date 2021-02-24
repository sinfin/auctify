# frozen_string_literal: true

require "test_helper"

module Auctify
  module Sale
    class AuctionBiddingTest < ActiveSupport::TestCase
      attr_reader :auction, :adam, :lucifer, :registrations

      setup do
        @auction = auctify_sales(:eve_apple)
        @auction.accept_offer
        assert @auction.valid?, "auction is not valid! : #{@auction.errors.full_messages}"

        @lucifer = users(:lucifer)
        @adam = users(:adam)

        @registrations = {}
        @registrations[@adam] = @auction.bidder_registrations.detect { |r| r.bidder == @adam }
        @registrations[@lucifer] = @auction.bidder_registrations.detect { |r| r.bidder == @lucifer }

        assert_equal [@adam, @lucifer], @auction.bidders
      end

      test "can process bids" do
        auction.offered_price = 1_000
        assert_nil auction.current_price

        auction.start_sale
        auction.save! # just for sure

        assert_equal 1_000, auction.reload.current_price

        assert_equal true, auction.bid!(bid_for(lucifer, 1_001))

        assert_equal 1_001, auction.current_price

        assert_equal false, auction.bid!(bid_for(lucifer, 1_002)) # You cannot overbid Yourself

        assert_equal 1_001, auction.current_price

        assert_equal true, auction.bid!(bid_for(adam, 1_002))

        assert_equal 1_002, auction.reload.current_price

        auction.close_bidding

        assert_equal 1_000, auction.offered_price
        assert_equal 1_002, auction.current_price
        assert_nil auction.sold_price

        bid = bid_for(lucifer, 10_000)
        assert_difference("Auctify::Bid.count", 0) do
          assert_equal false, auction.bid!(bid)
        end
        assert ["dad"], bid.errors

        auction.sold_in_auction(buyer: auction.winning_bid.bidder, price: auction.winning_bid.price)
        auction.save!

        assert_equal 1_002, auction.reload.sold_price
        assert_equal adam, auction.buyer
        assert_equal 2, auction.bids.size # only successfull bids are stored
      end

      def bid_for(bidder, price, max_price = nil)
        b_reg = registrations[bidder]
        Auctify::Bid.new(registration: b_reg, price: price, max_price: max_price)
      end
    end
  end
end
