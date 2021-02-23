# frozen_string_literal: true

require "test_helper"

module Auctify
  module Sale
    class AuctionBiddingTest < ActiveSupport::TestCase
      attr_reader :auction, :adam, :lucifer

      setup do
        @auction = auctify_sales(:eve_apple)
        @auction.accept_offer
        assert @auction.valid?, "auction is not valid! : #{@auction.errors.full_messages}"

        @lucifer = users(:lucifer)
        @adam = users(:adam)
        assert_equal [@adam, @lucifer], @auction.bidders
      end

      test "can process bids" do
        auction.offered_price = 1_000
        assert_nil auction.current_price

        auction.start_sale
        auction.save! # just for sure

        assert_equal 1_000, auction.reload.current_price
        assert_equal auction.current_price, auction.current_minimal_bid

        auction.bid!(bidder: lucifer, price: 1_001)

        assert_equal 1_001, auction.current_price
        assert_equal 1_002, auction.current_minimal_bid

        auction.bid!(bidder: lucifer, price: 1_002)

        assert_equal 1_001, auction.current_price # You cannot overbid Yourself
        assert_equal 1_002, auction.current_minimal_bid

        auction.bid!(bidder: adam, price: 1_002)

        assert_equal 1_002, auction.reload.current_price
        assert_equal 1_003, auction.current_minimal_bid

        auction.close_bidding

        assert_equal 1_000, auction.offered_price
        assert_equal 1_002, auction.current_price
        assert_nil auction.sold_price

        bid = auction.bid!(bidder: lucifer, price: 10_000)
        assert_equal ["too late"], bid.errors

        auction.sold_in_auction(buyer: auction.winning_bid.bidder, price: auction.winning_bid.price)
        auction.save!

        assert_equal 1_002, auction.reload.sold_price
        assert_equal adam, auction.buyer
      end
    end
  end
end
