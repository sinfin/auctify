# frozen_string_literal: true

require "application_system_test_case"

module Auctify
  class BidderRegistrationsTest < ApplicationSystemTestCase
    setup do
      @bidder_registration = auctify_bidder_registrations(:adam_on_apple)
    end

    test "visiting the index" do
      visit auctify_bidder_registrations_url
      assert_selector "h1", text: "Bidder Registrations"
    end

    test "creating a Bidder registration" do
      visit auctify_bidder_registrations_url
      click_on "New Bidder Registration"

      fill_in "Aasm state", with: @bidder_registration.aasm_state
      fill_in "Auction", with: @bidder_registration.auction_id
      fill_in "Bidder", with: @bidder_registration.bidder_id
      fill_in "Bidder type", with: @bidder_registration.bidder_type
      fill_in "Handled at", with: @bidder_registration.handled_at
      fill_in "Submitted at", with: @bidder_registration.submitted_at
      click_on "Create Bidder registration"

      assert_text "Bidder registration was successfully created"
      click_on "Back"
    end

    test "updating a Bidder registration" do
      visit auctify_bidder_registrations_url
      click_on "Edit", match: :first

      fill_in "Aasm state", with: @bidder_registration.aasm_state
      fill_in "Auction", with: @bidder_registration.auction_id
      fill_in "Bidder", with: @bidder_registration.bidder_id
      fill_in "Bidder type", with: @bidder_registration.bidder_type
      fill_in "Handled at", with: @bidder_registration.handled_at
      fill_in "Submitted at", with: @bidder_registration.submitted_at
      click_on "Update Bidder registration"

      assert_text "Bidder registration was successfully updated"
      click_on "Back"
    end

    test "destroying a Bidder registration" do
      visit auctify_bidder_registrations_url
      page.accept_confirm do
        click_on "Destroy", match: :first
      end

      assert_text "Bidder registration was successfully destroyed"
    end
  end
end
