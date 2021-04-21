# frozen_string_literal: true

require "test_helper"

module Auctify
  class BidderRegistrationsControllerTest < ActionDispatch::IntegrationTest
    include Engine.routes.url_helpers

    setup do
      @bidder_registration = auctify_bidder_registrations(:adam_on_apple)
    end

    test "should get index" do
      get auctify_bidder_registrations_url
      assert_response :success
    end

    test "should get new" do
      get new_auctify_bidder_registration_url
      assert_response :success
    end

    test "should create bidder_registration" do
      auction = auctify_sales(:auction_in_progress)
      assert_difference("Auctify::BidderRegistration.count") do
        post auctify_bidder_registrations_url,
             params: { bidder_registration: { auction_id: auction.id,
                                              bidder_id: users(:lucifer).id,
                                              bidder_type: "User" } }
      end

      assert_redirected_to auctify_bidder_registration_url(BidderRegistration.last)
    end

    test "should show bidder_registration" do
      get auctify_bidder_registration_url(@bidder_registration)
      assert_response :success
    end

    test "should get edit" do
      get edit_auctify_bidder_registration_url(@bidder_registration)
      assert_response :success
    end

    test "should update bidder_registration" do
      patch auctify_bidder_registration_url(@bidder_registration),
            params: { bidder_registration: { auction_id: @bidder_registration.auction_id,
                                             bidder_id: @bidder_registration.bidder_id,
                                             bidder_type: @bidder_registration.bidder_type,
                                             handled_at: @bidder_registration.handled_at } }
      assert_redirected_to auctify_bidder_registration_url(@bidder_registration)
    end

    test "should destroy bidder_registration" do
      assert_difference("Auctify::BidderRegistration.count", -1) do
        delete auctify_bidder_registration_url(@bidder_registration)
      end

      assert_redirected_to auctify_bidder_registrations_url
    end
  end
end
