# frozen_string_literal: true

require "test_helper"

module Auctify
  module Sale
    class AuctionConfigTest < ActiveSupport::TestCase
      attr_reader :auction, :registrations

      include Auctify::AuctionHelpers
      include ActiveJob::TestHelper

      test "when config :autoregister_all_users_as_bidders is set => do it" do
        users_count = User.count
        assert users_count.positive?
        auction = nil

        # default is []
        Auctify.configuration.stub(:autoregister_as_bidders_all_instances_of_classes, []) do
          auction = Auctify::Sale::Auction.create!(seller: users(:eve), item: things(:apple), offered_price: 123.4, ends_at: 1.day.from_now)
        end

        assert_equal 0, auction.bidder_registrations.size

        Auctify.configuration.stub(:autoregister_as_bidders_all_instances_of_classes, ["User"]) do
          auction = Auctify::Sale::Auction.create!(seller: users(:eve), item: things(:apple), offered_price: 123.4, ends_at: 1.day.from_now)
        end

        assert_equal users_count, auction.bidder_registrations.size
        assert_equal users_count, auction.bidder_registrations.approved.size, auction.bidder_registrations.to_json
      end

      test "when config :autoregister_all_users_as_bidders is set => new registration is created on first bid" do
        auction = auctify_sales(:auction_in_progress)
        noe = User.create!(name: "Noe", email: "noe@arch.sea", password: "Release_the_dove!")

        Auctify.configuration.stub(:autoregister_as_bidders_all_instances_of_classes, []) do
          assert_no_difference("BidderRegistration.count") do
            bid = Auctify::Bid.new(bidder: noe, price: 1000)

            assert_not auction.bid!(bid)

            assert_includes bid.errors[:auction], "dražitel není registrován k této aukci"
          end
        end

        Auctify.configuration.stub(:autoregister_as_bidders_all_instances_of_classes, ["User"]) do
          assert_difference("BidderRegistration.count", +1) do
            assert auction.bid!(Auctify::Bid.new(bidder: noe, price: 2000))
          end
        end

        assert_equal noe, auction.bidder_registrations.last.bidder
        assert_equal noe, auction.current_winner
      end


      test "prolongs auction time on bid within limit" do
        auction = auctify_sales(:accepted_auction)
        lucifer = users(:lucifer)
        adam = users(:adam)
        auction.bidder_registrations.approved.create!(bidder: adam)
        auction.bidder_registrations.approved.create!(bidder: lucifer)
        allow_bids_for([lucifer, adam], auction)

        original_end_time = Time.current + 1.hour
        limit = 2.minutes
        auction.ends_at = original_end_time
        auction.aasm_state = :accepted # redoing start_sale
        auction.start_sale!

        assert_equal original_end_time, auction.currently_ends_at
        assert_equal limit.to_i, Auctify.configuration.auction_prolonging_limit_in_seconds

        assert auction.bid!(bid_for(lucifer, 1_001))

        assert_equal original_end_time, auction.currently_ends_at

        just_before_limit_time = original_end_time - limit - 1.second
        Time.stub(:current, just_before_limit_time) { assert auction.bid!(bid_for(adam, 1_002)) }

        assert_equal original_end_time, auction.currently_ends_at

        breaking_limit_time = original_end_time - limit
        Time.stub(:current, breaking_limit_time) { assert auction.bid!(bid_for(lucifer, 1_003)) }

        assert_equal original_end_time, auction.currently_ends_at

        just_after_limit_time = original_end_time - limit + 1.second
        Time.stub(:current, just_after_limit_time) { assert auction.bid!(bid_for(adam, 1_004)) }
        # comparing time with seconds precision, use `.to_i`
        assert_equal (just_after_limit_time + limit).to_i, auction.currently_ends_at.to_i

        right_before_end_time = auction.currently_ends_at - 1.second
        Time.stub(:current, right_before_end_time) { assert auction.bid!(bid_for(lucifer, 1_005)) }
        assert_equal (right_before_end_time + limit).to_i, auction.currently_ends_at.to_i

        at_end_time = auction.currently_ends_at
        Time.stub(:current, at_end_time) { assert auction.bid!(bid_for(adam, 1_006)) }
        assert_equal (at_end_time + limit).to_i, auction.currently_ends_at.to_i

        end_time = auction.currently_ends_at
        Time.stub(:current, end_time + 1.second) { assert_not auction.bid!(bid_for(lucifer, 1_007)) }
        assert_equal end_time.to_i, auction.currently_ends_at.to_i
      end

      test "respects sale.auction_prolonging_limit_in_seconds change" do
        auction = auctify_sales(:accepted_auction)
        lucifer = users(:lucifer)
        adam = users(:adam)
        auction.bidder_registrations.approved.create!(bidder: adam)
        auction.bidder_registrations.approved.create!(bidder: lucifer)
        allow_bids_for([lucifer, adam], auction)

        original_end_time = Time.current + 1.hour
        auction.ends_at = original_end_time
        auction.aasm_state = :accepted # redoing start_sale
        auction.start_sale!

        limit = 2.minutes # default
        assert_equal original_end_time, auction.currently_ends_at
        assert_equal limit.to_i, auction.auction_prolonging_limit_in_seconds

        bid_time = original_end_time - limit - 1.second
        Time.stub(:current, bid_time) { assert auction.bid!(bid_for(lucifer, 1_002)) }

        assert_equal original_end_time.to_i, auction.currently_ends_at.to_i

        # lets enlarge limit without changing bid_time
        auction.stub(:auction_prolonging_limit_in_seconds, 10.minutes) do
          Time.stub(:current, bid_time) { assert auction.bid!(bid_for(adam, 1_003)) }
        end

        assert_equal (bid_time + 10.minutes).to_i, auction.currently_ends_at.to_i
      end

      test "preffers SalesPack#auction_prolonging_limit_in_seconds over config.auction_prolonging_limit_in_seconds" do
        auction = auctify_sales(:accepted_auction)
        assert_nil auction.pack
        assert_equal Auctify.configuration.auction_prolonging_limit_in_seconds, auction.auction_prolonging_limit_in_seconds

        auction = auctify_sales(:adam_innocence)

        assert auction.pack.present?
        assert_nil auction.pack.auction_prolonging_limit_in_seconds
        assert_equal Auctify.configuration.auction_prolonging_limit_in_seconds, auction.auction_prolonging_limit_in_seconds

        auction.pack.auction_prolonging_limit_in_seconds = 33.minutes
        assert_equal 33.minutes, auction.auction_prolonging_limit_in_seconds
      end

      test "stays on :bidding_closed whe config.autofinish_auction_after_bidding = false" do
        auction = auctify_sales(:auction_in_progress)
        assert_equal false, Auctify.configuration.autofinish_auction_after_bidding

        assert auction.in_sale?

        auction.close_bidding!

        assert auction.bidding_ended?
        assert_nil auction.sold_price
      end

      test "solves successfull auction and call specific event when config.autofinish_auction_after_bidding = false" do
        auction = auctify_sales(:auction_in_progress)

        assert auction.in_sale?
        assert_nil auction.sold_price
        assert_nil auction.buyer
        assert_equal users(:adam), auction.current_winner

        Auctify.configuration.stub(:autofinish_auction_after_bidding, true) do
          auction.stub(:success?, true) do
            auction.close_bidding!
          end
        end

        assert auction.auctioned_successfully?
        assert_equal auction.current_price, auction.sold_price
        assert_equal users(:adam), auction.buyer
      end

      test "solves unsuccessfull auction and call specific event when config.autofinish_auction_after_bidding = false" do
        auction = auctify_sales(:auction_in_progress)

        assert auction.in_sale?
        assert_nil auction.sold_price
        assert_nil auction.buyer

        Auctify.configuration.stub(:autofinish_auction_after_bidding, true) do
          auction.stub(:success?, false) do
            auction.stub(:no_winner?, true) do
              auction.close_bidding!
            end
          end
        end

        assert auction.auctioned_unsuccessfully?
        assert_nil auction.sold_price
        assert_nil auction.buyer
      end
    end
  end
end
