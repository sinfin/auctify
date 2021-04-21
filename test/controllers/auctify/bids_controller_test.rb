# frozen_string_literal: true

require "test_helper"

module Auctify
  class BidsControllerTest < ActionDispatch::IntegrationTest
    include Engine.routes.url_helpers

    setup do
      @bid = auctify_bids(:one)
    end

    test "should get index" do
      get auctify_bids_url
      assert_response :success
    end

    test "should get new" do
      get new_auctify_bid_url
      assert_response :success
    end

    test "should create bid" do
      assert_difference("Bid.count") do
        post auctify_bids_url,
params: { bid: { max_price: @bid.max_price, price: @bid.price, registration_id: @bid.registration.id } }
      end

      assert_redirected_to auctify_bid_url(Bid.last)
    end

    test "should show bid" do
      get auctify_bid_url(@bid)
      assert_response :success
    end

    test "should get edit" do
      get edit_auctify_bid_url(@bid)
      assert_response :success
    end

    test "should update bid" do
      patch auctify_bid_url(@bid),
params: { bid: { max_price: @bid.max_price, price: @bid.price, registration_id: @bid.registration_id } }
      assert_redirected_to auctify_bid_url(@bid)
    end

    test "should destroy bid" do
      assert_difference("Bid.count", -1) do
        delete auctify_bid_url(@bid)
      end

      assert_redirected_to auctify_bids_url
    end
  end
end
