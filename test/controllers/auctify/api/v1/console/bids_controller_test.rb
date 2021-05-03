# frozen_string_literal: true

require "test_helper"

module Auctify
  module Api
    module V1
      module Console
        class BidsControllerTest < ActionDispatch::IntegrationTest
          include Engine.routes.url_helpers
          include Auctify::AuctionHelpers

          attr_reader :auction, :adam, :lucifer

          setup do
            @auction = auctify_sales(:auction_in_progress)

            @lucifer = users(:lucifer)
            @adam = users(:adam)
            allow_bids_for([@lucifer, @adam], @auction)
            assert_equal [@adam, @lucifer], @auction.bidders

            assert auction.bid!(bid_for(lucifer, 1_001))
            assert auction.bid!(bid_for(adam, 1_100))
            assert_equal 1_100, auction.current_price
          end

          test "DELETE will just cancel bid and recalculate winner" do
            bid_to_cancel = bid_for(lucifer, 1_200)
            next_bid = bid_for(adam, 1_300)
            assert auction.bid!(bid_to_cancel)
            assert auction.bid!(next_bid)

            assert_equal 1_300, auction.current_price

            assert_no_difference("auction.bids.size") do
              assert_difference("auction.applied_bids.size", -1) do
                delete "/auctify/api/v1/console/bids/#{bid_to_cancel.id}"
              end
            end

            assert_response :success

            assert bid_to_cancel.reload.cancelled?
            assert_equal 1_300, auction.current_price
          end

          test "all actions are allowed for admin account only" do
            skip
            sign_in lucifer
          end


          # test "POST /api/auctions/:id/bids will create bid for current_user" do
          #   sign_in lucifer

          #   assert_difference("Auctify::Bid.count", +1) do
          #     post api_path_for("/auctions/#{auction.id}/bids"), params: { bid: { price: 1_200.0, max_price: 2_000.0 } }
          #     assert_response :ok, "Bid was not created, response.body is:\n #{response.body}"
          #   end

          #   auction.reload
          #   assert_auction_json_response

          #   assert_equal 1_101.0, auction.current_price.to_f # only autobidding was applied
          #   assert_equal lucifer, auction.current_winner

          #   bid = auction.bids.last
          #   assert_equal 1_101, bid.price
          #   assert_equal 2_000, bid.max_price
          #   assert_equal lucifer, bid.bidder
          # end

          # test "POST /api/auctions/:id/bids will handle not succesfull bid" do
          #   sign_in users(:eve) # not bidder for auction

          #   assert_no_difference("Auctify::Bid.count") do
          #     post api_path_for("/auctions/#{auction.id}/bids"), params: { bid: { price: 1_200.0, max_price: 2_000.0 } }
          #     assert_response 400, "Bid should not be created, response.body is:\n #{response.body}"
          #   end

          #   assert_includes response_json["errors"], { "status" => 400,
          #                                             "title" => "ActiveRecord::RecordInvalid",
          #                                             "detail" => "Auction dražitel není registrován k této aukci" }

          #   @response_json = nil
          #   sign_in adam # current winner

          #   assert_no_difference("Auctify::Bid.count") do
          #     post api_path_for("/auctions/#{auction.id}/bids"), params: { bid: { price: 1_200.0 } }
          #     assert_response 400, "Bid should not be created, response.body is:\n #{response.body}"
          #   end

          #   assert_includes response_json["errors"], { "status" => 400,
          #                                             "title" => "ActiveRecord::RecordInvalid",
          #                                             "detail" => "Bidder Není možné přehazovat své příhozy" }
          # end

          private
            def api_path_for(resource_path)
              "/auctify/api/v1/" + resource_path.match(/\/?(.*)/)[1]
            end

        end
      end
    end
  end
end
