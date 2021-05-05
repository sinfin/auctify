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
        assert_equal 1, auction.callback_runs[:after_start_sale]

        auction.save! # just for sure

        assert_equal 1_000, auction.reload.current_price

        assert auction.bid!(bid_for(lucifer, 1_001))
        assert_equal 1, auction.callback_runs[:after_bid_appended]

        assert_equal 1_001, auction.current_price

        assert_not auction.bid!(bid_for(lucifer, 1_002)) # You cannot overbid Yourself
        assert_equal 1, auction.callback_runs[:after_bid_not_appended]

        assert_equal 1_001, auction.current_price

        assert auction.bid!(bid_for(adam, 1_002))
        assert_equal 2, auction.callback_runs[:after_bid_appended]

        assert_equal 1_002, auction.reload.current_price

        auction.close_bidding
        assert_equal 1, auction.callback_runs[:after_close_bidding]

        assert_equal 1_000, auction.offered_price
        assert_equal 1_002, auction.current_price
        assert_nil auction.sold_price

        bid = bid_for(lucifer, 10_000)
        assert_no_difference("Auctify::Bid.count") do
          assert_equal false, auction.bid!(bid)
          assert_equal 2, auction.callback_runs[:after_bid_not_appended]
        end

        assert_includes bid.errors[:auction], "je momentálně uzavřena pro přihazování"

        auction.sold_in_auction(buyer: auction.winning_bid.bidder, price: auction.winning_bid.price)
        assert_equal 1, auction.callback_runs[:after_sold_in_auction]
        auction.save!

        assert_equal 1_002, auction.reload.sold_price
        assert_equal adam, auction.buyer
        assert_equal 2, auction.bids.size # only successfull bids are stored
      end

      test "get errors from failed bid" do
        auction.start_sale

        bid = Bid.new(price: 200_000, registration: nil)
        assert bid.errors.empty?

        assert_not auction.bid!(bid)

        assert bid.errors.present?
        assert_includes bid.errors[:auction], "dražitel není registrován k této aukci"
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

          assert auction.bids_count.zero?
          assert_nil auction.reserve_price

          assert_equal false, auction.success?, "`auction.success?` should return FALSE for #{st} state, but got #{auction.success?}"

          auction.stub(:bids_count, 1) do
            assert_equal true, auction.success?, "`auction.success?` should return TRUE for #{st} state, but got #{auction.success?}"

            auction.reserve_price = 1000
            assert_equal true, auction.success?, "`auction.success?` should return TRUE for #{st} state, but got #{auction.success?}"

            auction.reserve_price = 1001
            assert_equal false, auction.success?, "`auction.success?` should return FALSE for #{st} state, but got #{auction.success?}"
          end
        end
      end
    end
  end
end
