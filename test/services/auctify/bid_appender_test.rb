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

      bids_and_expectations = [
        { bid: { price: 1_001, max_price: nil, bidder: lucifer },
          appender: { success: true, errors: {} },
          auction_after: { current_price: 1_001, current_minimal_bid: 1_002, winner: lucifer, bids_count: 1 } },

        { bid: { price: 1_002, max_price: 3_000, bidder: adam },
          appender: { success: true, errors: {} },
          auction_after: { current_price: 1_002, current_minimal_bid: 1_003, winner: adam, bids_count: 2 } },

        # trying to beat Adam
        { bid: { price: 1_100, max_price: nil, bidder: lucifer },
          appender: { success: true, errors: {} },
          auction_after: { current_price: 1_101, current_minimal_bid: 1_102, winner: adam, bids_count: 4 } },
        #                                          bids_count: 2 + Lucifer's bid + Adam's autobid with increased price

        # battle of limits!
        { bid: { price: nil, max_price: 2_222, bidder: lucifer },
          appender: { success: true, errors: {} },
          auction_after: { current_price: 2_223, current_minimal_bid: 2_224, winner: adam, bids_count: 6 } },
        #                                          bids_count: 4 + Lucifer's bid + Adam's autobid with increased price

        # battle of times; when same price, first placed bid wins (Adam)
        { bid: { price: nil, max_price: 3_000, bidder: lucifer },
          appender: { success: true, errors: {} },
          auction_after: { current_price: 3_000, current_minimal_bid: 3_001, winner: adam, bids_count: 8 } },
        #                                          bids_count: 6 + Lucifer's bid + Adam's autobid with increased price

        # final Lucifer's attack
        { bid: { price: nil, max_price: 6_666, bidder: lucifer },
          appender: { success: true, errors: {} },
          auction_after: { current_price: 3_001, current_minimal_bid: 3_002, winner: lucifer, bids_count: 10 } },
        #    bids_count: 8 + Lucifer's winning bid (no updated Adam's autobid, because it is already at maximum price)
      ]

      appender = Auctify::BidsAppender.call(auction: auction, bid: nil)

      assert_equal auction.current_price, appender.result.current_minimal_bid
      assert_equal auction.current_price, appender.result.current_price
      assert_nil appender.result.winning_bid

      bids_and_expectations.each { |hash| place_bid_and_verfify_results(hash) }
      # resulting auction.bids (in DB):
      # lucifer:  "price":"1001.0","max_price":null
      # --------------------
      # adam:     "price":"1002.0","max_price":"3000.0"
      # --------------------
      # lucifer:  "price":"1100.0","max_price":null
      # adam:     "price":"1101.0","max_price":"3000.0"
      # --------------------
      # lucifer:  "price":"2222.0","max_price":"2222.0"
      # adam:     "price":"2223.0","max_price":"3000.0"
      # --------------------
      # adam:     "price":"3000.0","max_price":"3000.0"
      # lucifer:  "price":"3000.0","max_price":"3000.0"
      # --------------------
      # adam:     "price":"3000.0","max_price":"3000.0"
      # lucifer:  "price":"3001.0","max_price":"6666.0"
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

      bids_and_expectations = [
        { bid: { price: 1_000, max_price: nil, bidder: lucifer },
          appender: { success: true, errors: {} },
          auction_after: { current_price: 1_000, current_minimal_bid: 1_100, winner: lucifer, bids_count: 1 } },

        # too low bid
        { bid: { price: 1_099, max_price: nil, bidder: adam },
          appender: { success: false, errors: { price: ["je nižší než aktuální minimální příhoz"] } },
          auction_after: { current_price: 1_000, current_minimal_bid: 1_100, winner: lucifer, bids_count: 1 } },

        # exact bid
        { bid: { price: 1_100, max_price: nil, bidder: adam },
          appender: { success: true, errors: {} },
          auction_after: { current_price: 1_100, current_minimal_bid: 1_200, winner: adam, bids_count: 2 } },

        # higher than needed bid
        { bid: { price: 1_999, max_price: nil, bidder: lucifer },
          appender: { success: true, errors: {} },
          auction_after: { current_price: 1_999, current_minimal_bid: 2_099, winner: lucifer, bids_count: 3 } },

        # first bid with limit
        { bid: { price: nil, max_price: 2_500, bidder: adam },
          appender: { success: true, errors: {} },
          auction_after: { current_price: 2_099, current_minimal_bid: 2_199, winner: adam, bids_count: 4 } },
        #                                          bids_count: 4 + Lucifer's bid + Adam's autobid with increased price

        # second bid with limit
        # 2099 -> 2199 -> 2299 -> 2399 -> 2499 -> 2599
        { bid: { price: nil, max_price: 4_666, bidder: lucifer },
          appender: { success: true, errors: {} },
          auction_after: { current_price: 2_599, current_minimal_bid: 2_699, winner: lucifer, bids_count: 6 } },
        #                                          bids_count: 4 + Lucifer's bid + Adam's autobid with increased price

        # adam increases his limit (bidding will progress to next minimal bid step)
        # 2699 -> 2799 -> 2899 -> 2999 -> 3099 -> 3599 -> 4099
        { bid: { price: nil, max_price: 3_990, bidder: adam },
          appender: { success: true, errors: {} },
          auction_after: { current_price: 4_099, current_minimal_bid: 4_599, winner: lucifer, bids_count: 8 } }
        #                                          bids_count: 6 + Lucifer's bid + Adam's autobid with increased price
      ]

      bids_and_expectations.each { |hash| place_bid_and_verfify_results(hash) }
      # resulting auction.bids (in DB):
      # lucifer: "price":"1000.0","max_price":null
      # ---------------------
      # adam:    "price":"1100.0","max_price":null
      # ---------------------
      # lucifer: "price":"1999.0","max_price":null
      # ---------------------
      # adam:    "price":"2099.0","max_price":"2500.0"
      # ---------------------
      # adam:    "price":"2500.0","max_price":"2500.0"
      # lucifer: "price":"2599.0","max_price":"4666.0"
      # ---------------------
      # adam:    "price":"3990.0","max_price":"3990.0"
      # lucifer: "price":"4099.0","max_price":"4666.0"
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

    def place_bid_and_verfify_results(hash)
      bid = bid_for(hash[:bid][:bidder], hash[:bid][:price], hash[:bid][:max_price])
      appender = Auctify::BidsAppender.call(auction: auction, bid: bid)

      assert_equal hash[:appender][:success],
                   appender.success?,
                   "result was not #{hash[:success] ? "successfull" : "failure"} for #{hash}"
      assert_equal hash[:auction_after][:current_price],
                   appender.result.current_price,
                   "current price #{appender.result.current_price} do not match #{hash}"
      assert_equal hash[:auction_after][:current_minimal_bid],
                   appender.result.current_minimal_bid,
                   "min bid #{appender.result.current_minimal_bid} do not match #{hash}"
      assert_equal hash[:auction_after][:winner],
                   appender.result.winning_bid.bidder,
                   "winner #{appender.result.winning_bid.bidder} do not match #{hash}"

      assert_equal hash[:auction_after][:current_price],
                   auction.reload.current_price,
                   "auction.current_price #{auction.current_price} do not match #{hash}"
      assert_equal hash[:auction_after][:bids_count],
                   auction.bids.count,
                   "auction.bids.count #{auction.bids.count} do not match #{hash}" \
                   " => #{auction.bids.ordered.reverse.to_json}"

      if appender.failed?
        assert_equal hash[:appender][:errors],
                     appender.errors.to_h,
                     "expected appender errors #{hash[:appender][:errors]}," \
                     " but have #{appender.errors.to_h} for #{hash}"

        bid_error_always_in_arrays = bid.errors.to_h.transform_values { |value| [value].flatten }
        assert_equal hash[:appender][:errors],
                     bid_error_always_in_arrays,
                     "expected bid errors #{hash[:appender][:errors]}," \
                     " but have #{bid_error_always_in_arrays} for #{hash}"
      end
    end
  end
end
