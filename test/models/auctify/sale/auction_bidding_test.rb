# frozen_string_literal: true

require "test_helper"

module Auctify
  module Sale
    class AuctionBiddingTest < ActiveSupport::TestCase
      attr_reader :auction, :adam, :lucifer, :registrations

      include Auctify::AuctionHelpers

      setup do
        @auction = auctify_sales(:accepted_auction)

        assert @auction.valid?, "auction is not valid! : #{@auction.errors.full_messages}"

        @lucifer = users(:lucifer)
        @adam = users(:adam)

        allow_bids_for([@lucifer, @adam], @auction)

        assert_equal [@adam, @lucifer], @auction.bidders
      end

      test "can process bids" do
        auction.offered_price = 1_000

        assert_nil auction.current_price

        auction.start_sale
        auction.save! # just for sure

        assert_equal 1_000, auction.reload.current_price

        assert auction.bid!(bid_for(lucifer, 1_001))

        assert_equal 1_001, auction.current_price

        assert_not auction.bid!(bid_for(lucifer, 1_002)) # You cannot overbid Yourself

        assert_equal 1_001, auction.current_price

        assert auction.bid!(bid_for(adam, 1_002))

        assert_equal 1_002, auction.reload.current_price

        auction.close_bidding

        assert_equal 1_000, auction.offered_price
        assert_equal 1_002, auction.current_price
        assert_nil auction.sold_price

        bid = bid_for(lucifer, 10_000)
        assert_no_difference("Auctify::Bid.count") do
          assert_equal false, auction.bid!(bid)
        end

        assert_includes bid.errors[:auction], "je momentálně uzavřena pro přihazování"

        auction.sold_in_auction(buyer: auction.winning_bid.bidder, price: auction.winning_bid.price)
        auction.save!

        assert_equal 1_002, auction.reload.sold_price
        assert_equal adam, auction.buyer
        assert_equal 2, auction.bids.size # only successfull bids are stored
      end
    end
  end
end
