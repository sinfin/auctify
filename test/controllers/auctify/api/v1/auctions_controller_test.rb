# frozen_string_literal: true

require "test_helper"

module Auctify
  module Api
    module V1
      class AuctionsControllerTest < ActionDispatch::IntegrationTest
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

        test "GET #show returns auction info struct" do
          get "/auctify/api/v1/auctions/#{auction.id}"

          assert_response :success

          json = JSON.parse(response.body)
          assert_equal auction.id, json["auction"]["id"]
          assert_equal auction.current_winner.id, json["auction"]["current_winner"]["id"]
          assert_equal auction.current_winner.auctify_id, json["auction"]["current_winner"]["auctify_id"]
          assert_equal auction.current_winner.to_label, json["auction"]["current_winner"]["to_label"]
          assert_equal auction.current_price, json["auction"]["current_price"]
          assert_equal auction.current_minimal_bid, json["auction"]["current_minimal_bid"]
          assert_equal auction.ends_at, json["auction"]["ends_at"]
          assert_equal auction.currently_ends_at, json["auction"]["currently_ends_at"]
          assert_equal auction.open_for_bids?, json["auction"]["open_for_bids?"]
        end

        test "GET #SHOW returns 404 if no auction found" do
          skip
          # same for retail sale
        end
      end
    end
  end
end
