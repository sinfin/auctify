# frozen_string_literal: true

require "test_helper"

module Auctify
  class BidAppenderTest < ActiveSupport::TestCase
    attr_reader :auction, :adam, :lucifer, :registrations

    setup do
      @auction = auctify_sales(:eve_apple)
      @auction.accept_offer
      @auction.offered_price = 1_000
      @auction.start_sale
      @auction.save! # just for sure

      assert @auction.valid?, "auction is not valid! : #{@auction.errors.full_messages}"

      @lucifer = users(:lucifer)
      @adam = users(:adam)

      @registrations = {}
      @registrations[@adam] = @auction.bidder_registrations.detect { |r| r.bidder == @adam }
      @registrations[@lucifer] = @auction.bidder_registrations.detect { |r| r.bidder == @lucifer }

      assert_equal [@adam, @lucifer], @auction.bidders
    end


    test "adds bid and modify auctiion" do
      assert_equal 1_000, auction.reload.current_price

      appender = Auctify::BidsAppender.call(auction: auction, bid: nil)

      assert_equal auction.current_price, appender.result.current_minimal_bid
      assert_equal auction.current_price, appender.result.current_price
      assert_nil appender.result.winning_bid

      bid = bid_for(lucifer, 1_001)
      appender = Auctify::BidsAppender.call(auction: auction, bid: bid)

      assert_equal 1_002, appender.result.current_minimal_bid
      assert_equal 1_001, appender.result.current_price
      assert_equal bid, appender.result.winning_bid

      assert_equal 1_001, auction.reload.current_price # yes , appender updated auction
      assert_equal 1, auction.bids.count


      bid = bid_for(adam, 1_002)
      appender = Auctify::BidsAppender.call(auction: auction, bid: bid)

      assert_equal 1_003, appender.result.current_minimal_bid
      assert_equal 1_002, appender.result.current_price
      assert_equal bid, appender.result.winning_bid

      assert_equal 1_002, auction.reload.current_price
      assert_equal 2, auction.bids.count

      assert_equal adam, appender.result.winning_bid.bidder
    end

    test "can handle autobidding with max_price" do
    end

    test "do not allow bids until auction is running" do
      skip
    end

    test "can handle reserved_price" do
      skip
    end

    test "increase minimal bids in ranged steps" do
      skip
    end

    def bid_for(bidder, price, max_price = nil)
      b_reg = registrations[bidder]
      Auctify::Bid.new(registration: b_reg, price: price, max_price: max_price)
    end
  end
end
