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
        assert_nil auction.current_winner

        auction.start_sale
        assert_equal 1, auction.callback_runs[:after_start_sale]

        auction.save! # just for sure

        assert_equal 1_000, auction.reload.current_price
        assert_nil auction.current_winner
        assert_nil auction.current_winning_bid
        assert_nil auction.previous_winning_bid

        bid1 = bid_for(lucifer, 1_001)

        assert auction.bid!(bid1)

        assert_equal 1, auction.callback_runs[:after_bid_appended]
        assert_equal 1_001, auction.current_price
        assert_equal lucifer, auction.current_winner
        assert_equal bid1, auction.current_winning_bid
        assert_nil auction.previous_winning_bid

        bid2 = bid_for(lucifer, 1_002)

        assert_not auction.bid!(bid2) # You cannot overbid Yourself

        assert_equal 1, auction.callback_runs[:after_bid_not_appended]
        assert_equal 1_001, auction.current_price
        assert_equal lucifer, auction.current_winner
        assert_equal bid1, auction.current_winning_bid
        assert_nil auction.previous_winning_bid

        bid3 = bid_for(adam, 1_002)

        assert auction.bid!(bid3)

        assert_equal 2, auction.callback_runs[:after_bid_appended]
        assert_equal 1_002, auction.reload.current_price
        assert_equal adam, auction.current_winner
        assert_equal bid3, auction.current_winning_bid
        assert_equal bid1, auction.previous_winning_bid

        bid4 = bid_for(lucifer, nil, 5_000)

        assert auction.bid!(bid4)

        assert_equal 3, auction.callback_runs[:after_bid_appended]
        assert_equal 1_003, auction.reload.current_price
        assert_equal lucifer, auction.current_winner
        assert_equal bid4, auction.current_winning_bid
        assert_equal bid3, auction.previous_winning_bid

        bid5 = bid_for(adam, 2000)

        assert auction.bid!(bid5)

        assert_equal 4, auction.callback_runs[:after_bid_appended]
        assert_equal 2_001, auction.reload.current_price
        assert_equal lucifer, auction.current_winner
        # bid4 is with limit, so some autobidding happens => new offspring of bid4 is created
        assert_equal bid4.bidder, auction.current_winning_bid.bidder
        assert_equal bid4.max_price, auction.current_winning_bid.max_price
        assert_equal bid4, auction.previous_winning_bid(bid5)


        auction.close_bidding
        assert_equal 1, auction.callback_runs[:after_close_bidding]

        assert_equal 1_000, auction.offered_price
        assert_equal 2_001, auction.current_price
        assert_nil auction.sold_price

        bid6 = bid_for(adam, 10_000)

        assert_no_difference("Auctify::Bid.count") do
          assert_equal false, auction.bid!(bid6)
        end
        assert_equal 2, auction.callback_runs[:after_bid_not_appended]
        assert_includes bid6.errors[:auction], "je momentálně uzavřena pro přihazování"

        auction.sold_in_auction(buyer: auction.winning_bid.bidder, price: auction.winning_bid.price)
        assert_equal 1, auction.callback_runs[:after_sold_in_auction]
        auction.save!

        assert_equal 2_001, auction.reload.sold_price
        assert_equal lucifer, auction.buyer
        assert_equal (4 + 1), auction.bids.size # only successfull bids are stored
      end

      test "get errors from failed bid" do
        auction.start_sale

        bid = Bid.new(price: 200_000, registration: nil)
        assert bid.errors.empty?

        assert_not auction.bid!(bid)

        assert bid.errors.present?
        assert_includes bid.errors[:auction], "dražitel není registrován k této aukci"
      end

      test "verify bidder before processing bid" do
        auction.offered_price = 1_000
        auction.start_sale!

        auction.stub(:bidding_allowed_for?, true) do
          assert auction.bid!(bid_for(lucifer, 1_001))
        end

        auction.stub(:bidding_allowed_for?, false) do
          bid = bid_for(adam, 1_100)
          assert_not auction.bid!(bid)
          assert_includes bid.errors[:bidder], "Nemáte povoleno dražit"
        end
      end

      test "create registration if bidder responds to `register_to auction_on_first_bid?`" do
      end

      test "can say, if it is #succes?" do
        all_states = auction.aasm.states.collect(&:name)
        not_decided_states = %i[offered accepted refused cancelled in_sale]
        success_states = %i[auctioned_successfully sold]
        fail_states = %i[auctioned_unsuccessfully not_sold]

        other_states = all_states - not_decided_states - success_states - fail_states
        assert_equal [:bidding_ended], other_states

        not_decided_states.each do |st|
          auction.aasm_state = st
          assert_nil auction.success?, "`auction.success?` should return NIL for #{st} state, but got #{auction.success?}"
        end

        success_states.each do |st|
          auction.aasm_state = st
          assert_equal true, auction.success?, "`auction.success?` should return TRUE for #{st} state, but got #{auction.success?}"
        end

        fail_states.each do |st|
          auction.aasm_state = st
          assert_equal false, auction.success?, "`auction.success?` should return FALSE for #{st} state, but got #{auction.success?}"
        end

        other_states.each do |st|
          auction.aasm_state = st
          auction.current_price = 1000

          assert auction.applied_bids_count.zero?
          assert_nil auction.reserve_price

          assert_equal false, auction.success?, "`auction.success?` should return FALSE for #{st} state, but got #{auction.success?}"

          auction.stub(:applied_bids_count, 1) do
            assert_equal true, auction.success?, "`auction.success?` should return TRUE for #{st} state, but got #{auction.success?}"

            auction.reserve_price = 1000
            assert_equal true, auction.success?, "`auction.success?` should return TRUE for #{st} state, but got #{auction.success?}"

            auction.reserve_price = 1001
            assert_equal false, auction.success?, "`auction.success?` should return FALSE for #{st} state, but got #{auction.success?}"
          end
        end
      end

      test "do not append invalid bid" do
        Auctify.configuration.stub(:require_bids_to_be_rounded_to, 100) do
          auction.offered_price = 1_000
          auction.start_sale
          auction.save! # just for sure

          assert_equal 1_000, auction.reload.current_price

          bid1 = bid_for(lucifer, 1_000)

          assert auction.bid!(bid1)

          assert_equal 1_000, auction.current_price
          assert_equal lucifer, auction.current_winner

          bid2 = bid_for(adam, nil, 5_000)

          assert auction.bid!(bid2), bid2.errors.full_messages

          assert_equal 1_100, auction.reload.current_price
          assert_equal adam, auction.current_winner
          assert_equal bid2, auction.current_winning_bid

          bid3 = bid_for(lucifer, 2_222)

          assert_equal false, auction.bid!(bid3)

          assert_includes bid3.errors[:price], "musí být zaokrouhlená na celé 100 Kč"

          assert_equal 1_100, auction.current_price
          assert_equal adam, auction.current_winner
          assert_equal bid2, auction.current_winning_bid
          assert_equal 2, auction.bids.count

          bid4 = bid_for(lucifer, nil, 2_222)

          assert_equal false, auction.bid!(bid4)

          assert_includes bid4.errors[:max_price], "musí být zaokrouhlená na celé 100 Kč"

          assert_equal 1_100, auction.current_price
          assert_equal adam, auction.current_winner
          assert_equal bid2, auction.current_winning_bid
          assert_equal 2, auction.bids.count
        end
      end
    end
  end
end
