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


    test "adds bid and modify auction" do
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
      assert_equal 1_000, auction.reload.current_price

      appender = Auctify::BidsAppender.call(auction: auction, bid: nil)

      assert_equal auction.current_price, appender.result.current_minimal_bid
      assert_equal auction.current_price, appender.result.current_price
      assert_nil appender.result.winning_bid

      appender = Auctify::BidsAppender.call(auction: auction, bid: bid_for(lucifer, 1_001))

      assert_equal 1_001, appender.result.current_price
      assert_equal 1_002, appender.result.current_minimal_bid
      assert_equal lucifer, appender.result.winning_bid.bidder

      assert_equal 1_001, auction.reload.current_price # yes, appender updated auction
      assert_equal 1, auction.bids.count

      appender = Auctify::BidsAppender.call(auction: auction, bid: bid_for(adam, 1_002, 3_000))

      assert_equal 1_002, appender.result.current_price
      assert_equal 1_003, appender.result.current_minimal_bid
      assert_equal adam, appender.result.winning_bid.bidder

      assert_equal 1_002, auction.reload.current_price
      assert_equal 2, auction.bids.count

      # trying to beat Adam
      appender = Auctify::BidsAppender.call(auction: auction, bid: bid_for(lucifer, 1_100))

      assert_equal 1_101, appender.result.current_price
      assert_equal 1_102, appender.result.current_minimal_bid
      assert_equal adam, appender.result.winning_bid.bidder

      assert_equal 1_101, auction.reload.current_price
      assert_equal 4, auction.bids.count # 2 + Lucifer's bid + Adam's autobid with increased price

      # battle of limits!
      appender = Auctify::BidsAppender.call(auction: auction, bid: bid_for(lucifer, nil, 2_222))

      assert_equal 2_223, appender.result.current_price
      assert_equal 2_224, appender.result.current_minimal_bid
      assert_equal adam, appender.result.winning_bid.bidder

      assert_equal 6, auction.bids.count # 4 + Lucifer's bid + Adam's autobid with increased price

      # battle of times; when same price, first placed bid wins
      appender = Auctify::BidsAppender.call(auction: auction, bid: bid_for(lucifer, nil, 3_000))

      assert_equal 3_000, appender.result.current_price
      assert_equal 3_001, appender.result.current_minimal_bid
      assert_equal adam, appender.result.winning_bid.bidder

      assert_equal 8, auction.bids.count # 6 + Lucifer's bid + Adam's autobid with increased price

      # final attack
      appender = Auctify::BidsAppender.call(auction: auction, bid: bid_for(lucifer, nil, 6_666))

      assert_equal 3_001, appender.result.current_price
      assert_equal 3_002, appender.result.current_minimal_bid
      assert_equal lucifer, appender.result.winning_bid.bidder

      assert_equal 9, auction.bids.count # 8 + Lucifer's winnig bid
      # (no updated Adam's autobid, because it is already at maximum price)
    end

    test "do not allow bids when auction is not running" do
      no_bidding_allowed_states = auction.aasm.states.collect(&:name) - [:in_sale]
      no_bidding_allowed_states.each do |state|
        auction.aasm_state = state

        bid = bid_for(adam, 1_002)
        appender = Auctify::BidsAppender.call(auction: auction, bid: bid)

        assert appender.failure?
        assert_equal ["je momentálně uzavřena pro přihazování"], appender.errors[:auction]
        assert_equal ["je momentálně uzavřena pro přihazování"], bid.errors[:auction]
      end
    end

    test "can handle reserve_price" do
      skip # bids are accepted, but unles reserve price is overcome no deal is made
    end

    test "if no auction.bid_steps_ladder is blank, minimal bid increase is 1" do
      auction.bid_steps_ladder = nil
      assert_equal 1_000, auction.reload.current_price

      appender = Auctify::BidsAppender.call(auction: auction, bid: nil)

      assert_equal auction.current_price, appender.result.current_minimal_bid
      assert_equal auction.current_price, appender.result.current_price

      appender = Auctify::BidsAppender.call(auction: auction, bid: bid_for(lucifer, 1_000))

      assert_equal 1_000, appender.result.current_price
      assert_equal 1_001, appender.result.current_minimal_bid
    end

    test "if no auction.bid_steps_ladder is present, minimal bid is increased according to it" do
      # You CAN bid out of steps (eg  3666,-)
      # next minimal bid is calculated from current price and current step; even if new value is in next step

      auction.update!(bid_steps_ladder: { (0...3_000) => 100, (3_000...5_000) => 500, (5_000..) => 1_000 })
      assert_equal 1_000, auction.reload.current_price

      appender = Auctify::BidsAppender.call(auction: auction, bid: nil)

      assert_equal auction.current_price, appender.result.current_minimal_bid
      assert_equal auction.current_price, appender.result.current_price
      assert_nil appender.result.winning_bid

      appender = Auctify::BidsAppender.call(auction: auction, bid: bid_for(lucifer, 1_000))

      assert appender.success?
      assert_equal 1_000, appender.result.current_price
      assert_equal 1_100, appender.result.current_minimal_bid

      # too low bid
      bid = bid_for(adam, 1_099)
      appender = Auctify::BidsAppender.call(auction: auction, bid: bid)

      assert appender.failed?
      assert_equal ["je nižší než aktuální minimální příhoz"], appender.errors[:price]
      assert_equal ["je nižší než aktuální minimální příhoz"], bid.errors[:price]

      # exact bid
      appender = Auctify::BidsAppender.call(auction: auction, bid: bid_for(adam, 1_100))

      assert appender.success?
      assert_equal 1_100, appender.result.current_price
      assert_equal 1_200, appender.result.current_minimal_bid
      assert_equal adam, appender.result.winning_bid.bidder

      # higher than need bid
      appender = Auctify::BidsAppender.call(auction: auction, bid: bid_for(lucifer, 1_999))

      assert appender.success?
      assert_equal 1_999, appender.result.current_price
      assert_equal 2_099, appender.result.current_minimal_bid
      assert_equal lucifer, appender.result.winning_bid.bidder

      # bid with limit
      appender = Auctify::BidsAppender.call(auction: auction, bid: bid_for(adam, nil, 2_500))

      assert appender.success?
      assert_equal 2_099, appender.result.current_price
      assert_equal 2_199, appender.result.current_minimal_bid
      assert_equal adam, appender.result.winning_bid.bidder

      # second bid with limit
      # 2099 -> 2199 -> 2299 -> 2399 -> 2499 -> 2599
      appender = Auctify::BidsAppender.call(auction: auction, bid: bid_for(lucifer, nil, 4_666))

      assert appender.success?
      assert_equal 2_599, appender.result.current_price
      assert_equal 2_699, appender.result.current_minimal_bid
      assert_equal lucifer, appender.result.winning_bid.bidder

      # adam increases his limit (biddin will progress to next min bid step)
      # 2699 -> 2799 -> 2899 -> 2999 -> 3099 -> 3599 -> 4099
      appender = Auctify::BidsAppender.call(auction: auction, bid: bid_for(adam, nil, 3_990))

      assert appender.success?
      assert_equal 4_099, appender.result.current_price
      assert_equal 4_599, appender.result.current_minimal_bid
      assert_equal lucifer, appender.result.winning_bid.bidder
    end

    test " You cannot overbid yourself by price only bid" do
      skip
    end

    test " You can increase you own max_price" do
      skip
    end

    def bid_for(bidder, price, max_price = nil)
      b_reg = registrations[bidder]
      Auctify::Bid.new(registration: b_reg, price: price, max_price: max_price)
    end
  end
end
