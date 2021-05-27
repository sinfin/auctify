# frozen_string_literal: true

require "test_helper"

module Auctify
  class BidAppenderTest < ActiveSupport::TestCase
    attr_reader :auction, :adam, :lucifer, :registrations

    include Auctify::AuctionHelpers

    setup do
      @auction = auctify_sales(:accepted_auction)
      @auction.offered_price = 1_000
      @auction.ends_at = Time.current + 1.hour
      @auction.start_sale
      assert_nil @auction.buyer
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
      assert_equal bid, appender.bid
      assert_equal auction, appender.auction

      assert_equal 1_001, auction.reload.current_price # yes , appender updated auction
      assert_equal 1, auction.bids.count


      bid = bid_for(adam, 1_002)
      appender = Auctify::BidsAppender.call(auction: auction, bid: bid)

      assert_equal 1_003, appender.result.current_minimal_bid
      assert_equal 1_002, appender.result.current_price
      assert_equal bid, appender.result.winning_bid
      assert_equal bid, appender.bid
      assert_equal auction, appender.auction

      assert_equal 1_002, auction.reload.current_price
      assert_equal 2, auction.bids.count

      assert_equal adam, appender.result.winning_bid.bidder

      assert_nil auction.buyer
    end

    test "if price AND max_price is passed first price up then autobid" do
      skip "TODO: not implemented"
      # currently only autobidding happens so current_price can be lower than :price "
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
          auction_after: { current_price: 3_001, current_minimal_bid: 3_002, winner: lucifer, bids_count: 9 } },
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

      assert_nil auction.buyer
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
      auction.update(reserve_price: 2000)
      assert_equal 1_000, auction.reload.current_price

      bids_and_expectations = [
        { bid: { price: 1_001, max_price: nil, bidder: lucifer },
          appender: { success: true, errors: {} },
          auction_after: { current_price: 1_001, current_minimal_bid: 1_002, winner: nil, bids_count: 1 } },

        { bid: { price: 1_002, max_price: nil, bidder: adam },
          appender: { success: true, errors: {} },
          auction_after: { current_price: 1_002, current_minimal_bid: 1_003, winner: nil, bids_count: 2 } },

        { bid: { price: 1_999, max_price: nil, bidder: lucifer },
          appender: { success: true, errors: {} },
          auction_after: { current_price: 1_999, current_minimal_bid: 2_000, winner: nil, bids_count: 3 } },

        { bid: { price: 2000, bidder: adam },
          appender: { success: true, errors: {} },
          auction_after: { current_price: 2_000, current_minimal_bid: 2_001, winner: adam, bids_count: 4 } },

      ]

      bids_and_expectations[0..-1].each { |hash| place_bid_and_verfify_results(hash) }
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

    test "if auction.bid_steps_ladder is present, minimal bid is increased according to it" do
      # You CAN bid out of defined steps (eg  3666,-)
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
          appender: { success: false, errors: { price: ["je nižší než aktuální minimální příhoz 1 100 Kč"] } },
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

        # second bid with limit
        # 2099 -> 2199 -> 2299 -> 2399 -> 2499 -> 2599
        { bid: { price: nil, max_price: 4_666, bidder: lucifer },
          appender: { success: true, errors: {} },
          auction_after: { current_price: 2_599, current_minimal_bid: 2_699, winner: lucifer, bids_count: 6 } },

        # adam increases his limit (bidding will progress to next minimal bid step)
        # 2699 -> 2799 -> 2899 -> 2999 -> 3099 -> 3599 -> 4099
        { bid: { price: nil, max_price: 3_990, bidder: adam },
          appender: { success: true, errors: {} },
          auction_after: { current_price: 4_099, current_minimal_bid: 4_599, winner: lucifer, bids_count: 8 } },

        # adam do direct bid, which is less then bid-step beneath lucifers limit
        # 2699 -> 2799 -> 2899 -> 2999 -> 3099 -> 3599 -> 4099 -> 4601 -> 4666
        { bid: { price: 4601, max_price: nil, bidder: adam },
          appender: { success: true, errors: {} },
          auction_after: { current_price: 4_666, current_minimal_bid: 5166, winner: lucifer, bids_count: 10 } }
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

      assert_nil auction.buyer

      auction.close_bidding!

      assert auction.bidding_ended?

      auction.sold_in_auction(buyer: auction.winning_bid.bidder, price: auction.winning_bid.price)

      assert_equal lucifer, auction.buyer
    end

    test "bidder cannot overbid itself by price-only bid" do
      bids_and_expectations = [
        { bid: { price: 1_000, max_price: nil, bidder: lucifer },
          appender: { success: true, errors: {} },
          auction_after: { current_price: 1_000, current_minimal_bid: 1_001, winner: lucifer, bids_count: 1 } },

        # overbidding
        { bid: { price: 1_001, max_price: nil, bidder: lucifer },
          appender: { success: false, errors: { bidder: ["Není možné přehazovat své příhozy"] } },
          auction_after: { current_price: 1_000, current_minimal_bid: 1_001, winner: lucifer, bids_count: 1 } }
      ]

      bids_and_expectations.each { |hash| place_bid_and_verfify_results(hash) }
    end

    test "bidder can increase you own max_price" do
      bids_and_expectations = [
        { bid: { price: 1_000, max_price: 1_500, bidder: lucifer },
          appender: { success: true, errors: {} },
          auction_after: { current_price: 1_000, current_minimal_bid: 1_001, winner: lucifer, bids_count: 1 } },

        # increasing max_price
        { bid: { price: 1_000, max_price: 2_000, bidder: lucifer },
          appender: { success: true, errors: {} },
          auction_after: { current_price: 1_000, current_minimal_bid: 1_001, winner: lucifer, bids_count: 2 } },
      ]

      bids_and_expectations.each { |hash| place_bid_and_verfify_results(hash) }
    end

    test "two bids with same limit, first one wins" do
      assert_equal 1_000, auction.reload.current_price

      bid_l = bid_for(lucifer, nil, 3_000)
      appender = Auctify::BidsAppender.call(auction: auction, bid: bid_l)

      assert appender.success?
      assert_equal 1_000, auction.current_price
      assert_equal lucifer, auction.current_winner

      bid_a = bid_for(adam, nil, 3_000)
      appender = Auctify::BidsAppender.call(auction: auction, bid: bid_a)

      assert appender.success?
      assert_equal 3_000, auction.current_price
      assert_equal lucifer, auction.current_winner
    end

    test "ultimate bidding test" do
      assert_equal 1_000, auction.reload.current_price
      auction.update!(bid_steps_ladder: { (0..) => 100 })

      # time	| bidder A | bidder L	| limit for A | limit for L |	current price	| current_winner
      # -----------------------------------------------------------------------------------------
      #   1	    P:1000		            1000          0	            1000	          A
      #   2		             P:2000	    1000          2000          2000	          L
      #   3	    MP:5000		            5000	        2000	        2100	          A
      #   4	    P:3000 +
      #         MP:6000		            6000	        2000	        3000	          A
      #   5		             P:4000	    6000	        4000	        4100	          A
      #   6	    MP:7000		            7000	        4000	        4100	          A
      #   7		             MP:5000	  7000	        5000	        5100	          A
      #   8		             MP:7000	  7000	        7000	        7000	          A
      #   9		             MP:8000	  7000	        8000	        7100	          L
      #  10	    P:8000		            8000	        8000	        8000	          L
      #  11	    P:9000                9000          8000          9000            A
      #  12	    MP:10000		          10000	        8000	        9000	          A

      bids_and_expectations = [
        { bid: { price: 1_000, max_price: nil, bidder: adam },
          auction_after: { current_price: 1_000, current_minimal_bid: 1_100, winner: adam, bids_count: 1 },
          limits_after: { adam: 1_000, lucifer: 0 } },

        { bid: { price: 2_000, max_price: nil, bidder: lucifer },
          auction_after: { current_price: 2_000, current_minimal_bid: 2_100, winner: lucifer, bids_count: 2 },
          limits_after: { adam: 1_000, lucifer: 2_000 } },

        { bid: { price: nil, max_price: 5_000, bidder: adam },
          auction_after: { current_price: 2_100, current_minimal_bid: 2_200, winner: adam, bids_count: 3 },
          limits_after: { adam: 5_000, lucifer: 2_000 } },

        { bid: { price: 3_000, max_price: 6_000, bidder: adam }, # increasing own limit immediatelly with also price change
          auction_after: { current_price: 3_000, current_minimal_bid: 3_100, winner: adam, bids_count: 4 },
          limits_after: { adam: 6_000, lucifer: 2_000 } },

        { bid: { price: 4_000, max_price: nil, bidder: lucifer },
          auction_after: { current_price: 4_100, current_minimal_bid: 4_200, winner: adam, bids_count: 6 },
          limits_after: { adam: 6_000, lucifer: 4_000 } },

        { bid: { price: nil, max_price: 7_000, bidder: adam }, # increasing own limit, when winning
          auction_after: { current_price: 4_100, current_minimal_bid: 4_200, winner: adam, bids_count: 7 },
          limits_after: { adam: 7_000, lucifer: 4_000 } },

        { bid: { price: nil, max_price: 5_000, bidder: lucifer }, # increasing own limit, when losing => too low
          auction_after: { current_price: 5_100, current_minimal_bid: 5_200, winner: adam, bids_count: 9 },
          limits_after: { adam: 7_000, lucifer: 5_000 } },

        { bid: { price: nil, max_price: 7_000, bidder: lucifer },  # same limit as Adam!
          auction_after: { current_price: 7_000, current_minimal_bid: 7_100, winner: adam, bids_count: 11 },
          limits_after: { adam: 7_000, lucifer: 7_000 } },

        { bid: { price: nil, max_price: 8_000, bidder: lucifer }, # increasing own limit, when losing => high enough
          auction_after: { current_price: 7_100, current_minimal_bid: 7_200, winner: lucifer, bids_count: 12 },
          limits_after: { adam: 7_000, lucifer: 8_000 } },

        { bid: { price: 8_000, max_price: nil, bidder: adam },  # price change, when losing => equal limits
          auction_after: { current_price: 8_000, current_minimal_bid: 8_100, winner: lucifer, bids_count: 14 },
          limits_after: { adam: 8_000, lucifer: 8_000 } },

        { bid: { price: 9_000, max_price: nil, bidder: adam }, # overcoming limit with simple price
          auction_after: { current_price: 9_000, current_minimal_bid: 9_100, winner: adam, bids_count: 15 },
          limits_after: { adam: 9_000, lucifer: 8_000 } },

        { bid: { price: nil, max_price: 10_000, bidder: adam }, # securing my own winning price with limit
          auction_after: { current_price: 9_000, current_minimal_bid: 9_100, winner: adam, bids_count: 16 },
          limits_after: { adam: 10_000, lucifer: 8_000 } },
      ]

      appender = Auctify::BidsAppender.call(auction: auction, bid: nil)

      assert_equal auction.current_price, appender.result.current_minimal_bid
      assert_equal auction.current_price, appender.result.current_price
      assert_nil appender.result.winning_bid

      appended_bid = { appender: { success: true, errors: {} },  }

      bids_and_expectations.each do |hash|
        place_bid_and_verfify_results(hash.merge(appended_bid))
        # puts("bids.ordered: \n#{auction.bids.ordered.collect(&:to_json).join("\n")} \n\n")
      end
    end

    def place_bid_and_verfify_results(hash)
      bid = bid_for(hash[:bid][:bidder], hash[:bid][:price], hash[:bid][:max_price])
      appender = Auctify::BidsAppender.call(auction: auction, bid: bid)

      assert_equal hash[:appender][:success],
                   appender.success?,
                   "result was not #{hash[:appender][:success] ? "successfull" : "failure"} for #{hash} \nERR:#{appender.errors}"
      assert_equal hash[:auction_after][:current_price],
                   appender.result.current_price,
                   "current price #{appender.result.current_price} do not match #{hash}"
      assert_equal hash[:auction_after][:current_minimal_bid],
                   appender.result.current_minimal_bid,
                   "min bid #{appender.result.current_minimal_bid} do not match #{hash}"
      if hash[:auction_after][:winner].nil?
        assert_nil appender.result.winner,
                   "winner #{appender.result.winner} should be nil"
      else
        assert_equal hash[:auction_after][:winner],
                     appender.result.winner,
                     "winner #{appender.result.winner} do not match #{hash}"
      end

      assert_equal hash[:auction_after][:current_price],
                   auction.reload.current_price,
                   "auction.current_price #{auction.current_price} do not match #{hash}"
      assert_equal hash[:auction_after][:bids_count],
                   auction.bids.count,
                   "auction.bids.count #{auction.bids.count} do not match #{hash}" \
                   " \n=> #{auction.bids.ordered.reverse.collect(&:to_json).join("\n")}"

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

      if hash[:limits_after]
        hash[:limits_after].each_pair do |bidder_sym, limit|
          assert_equal limit, auction.current_max_price_for(send(bidder_sym))
        end
      end
    end
  end
end
