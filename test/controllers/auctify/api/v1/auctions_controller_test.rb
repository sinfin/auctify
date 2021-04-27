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

          assert_equal auction.id, json["data"]["id"].to_i
          assert_equal "auction", json["data"]["type"]

          json_attributes = json["data"]["attributes"]
          assert_equal auction.current_winner.id, json_attributes["current_winner"]["id"]
          assert_equal auction.current_winner.auctify_id, json_attributes["current_winner"]["auctify_id"]
          assert_equal auction.current_winner.to_label, json_attributes["current_winner"]["to_label"]

          assert_equal auction.current_price.to_f, json_attributes["current_price"].to_f
          assert_equal auction.current_minimal_bid.to_f, json_attributes["current_minimal_bid"].to_f
          assert_equal auction.ends_at, json_attributes["ends_at"]
          assert_equal auction.currently_ends_at, json_attributes["currently_ends_at"]
          assert_equal auction.open_for_bids?, json_attributes["open_for_bids?"]
        end

        test "GET #SHOW returns 404 if no auction found" do
          skip
          # same for retail sale
        end
      end
    end
  end
end
