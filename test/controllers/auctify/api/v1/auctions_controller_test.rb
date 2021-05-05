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

          assert_auction_json_response
        end

        test "GET #SHOW returns 404 if no auction found" do
          get "/auctify/api/v1/auctions/#{Auctify::Sale::Base.maximum(:id) + 1}"

          assert_response :not_found
        end

        test "GET #SHOW returns 404 if sale is not auction" do
          retail_sale = auctify_sales(:adam_innocence)
          assert_not retail_sale.is_a?(Auctify::Sale::Auction)

          get "/auctify/api/v1/auctions/#{retail_sale.id}"

          assert_response :not_found
        end

        test "POST /api/auctions/:id/bids will create bid for current_user" do
          sign_in lucifer

          assert_difference("Auctify::Bid.count", +1) do
            post api_path_for("/auctions/#{auction.id}/bids"), params: { bid: { price: 1_200.0, max_price: 2_000.0 } }

            assert_response :ok, "Bid was not created, response.body is:\n #{response.body}"
          end

          auction.reload
          assert_auction_json_response

          assert_equal 1_101.0, auction.current_price.to_f # only autobidding was applied
          assert_equal lucifer, auction.current_winner

          bid = auction.bids.last
          assert_equal 1_101, bid.price
          assert_equal 2_000, bid.max_price
          assert_equal lucifer, bid.bidder
        end

        test "POST /api/auctions/:id/bids will create bid and registration for current_user" do
          Auctify.configure do |config|
            config.autoregister_as_bidders_all_instances_of_classes = ["User"]
          end

          noe = User.create!(name: "Noe", email: "noe@arch.sea", password: "Release_the_dove!")
          assert_not_includes auction.bidders, noe

          sign_in noe

          assert_difference("Auctify::Bid.count", +1) do
            assert_difference("Auctify::BidderRegistration.count", +1) do
              post api_path_for("/auctions/#{auction.id}/bids"), params: { bid: { max_price: 2_000.0 } }

              assert_response :ok, "Bid was not created, response.body is:\n #{response.body}"
            end
          end

          auction.reload

          assert_equal 1_101.0, auction.current_price.to_f # only autobidding was applied
          assert_equal noe, auction.current_winner

          Auctify.configure do |config|
            config.autoregister_as_bidders_all_instances_of_classes = []
          end
        end

        test "POST /api/auctions/:id/bids will handle not succesfull bid" do
          sign_in users(:eve) # not bidder for auction

          assert_no_difference("Auctify::Bid.count") do
            post api_path_for("/auctions/#{auction.id}/bids"), params: { bid: { price: 1_200.0, max_price: 2_000.0 } }

            assert_response 400, "Bid should not be created, response.body is:\n #{response.body}"
          end

          assert_includes response_json["errors"], { "status" => 400,
                                                     "title" => "ActiveRecord::RecordInvalid",
                                                     "detail" => "Auction dražitel není registrován k této aukci" }

          @response_json = nil
          sign_in adam # current winner

          assert_no_difference("Auctify::Bid.count") do
            post api_path_for("/auctions/#{auction.id}/bids"), params: { bid: { price: 1_200.0 } }

            assert_response 400, "Bid should not be created, response.body is:\n #{response.body}"
          end

          assert_includes response_json["errors"], { "status" => 400,
                                                     "title" => "ActiveRecord::RecordInvalid",
                                                     "detail" => "Bidder Není možné přehazovat své příhozy" }
        end

        private
          def assert_auction_json_response
            assert_equal auction.id, response_json["data"]["id"].to_i
            assert_equal "auction", response_json["data"]["type"]

            json_attributes = response_json["data"]["attributes"]
            assert_equal auction.current_winner.id, json_attributes["current_winner"]["id"]
            assert_equal auction.current_winner.auctify_id, json_attributes["current_winner"]["auctify_id"]
            assert_equal auction.current_winner.to_label, json_attributes["current_winner"]["to_label"]

            assert_equal auction.current_price.to_f, json_attributes["current_price"].to_f
            assert_equal auction.current_minimal_bid.to_f, json_attributes["current_minimal_bid"].to_f
            assert_equal auction.ends_at, json_attributes["ends_at"]
            assert_equal auction.currently_ends_at, json_attributes["currently_ends_at"]
            assert_equal auction.open_for_bids?, json_attributes["open_for_bids?"]
          end

          def api_path_for(resource_path)
            "/auctify/api/v1/" + resource_path.match(/\/?(.*)/)[1]
          end

          def response_json
            @response_json ||= JSON.parse(Capybara.string(response.parsed_body["data"]).native.inner_text)
          end
      end
    end
  end
end
