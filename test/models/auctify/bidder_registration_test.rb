# frozen_string_literal: true

require "test_helper"

module Auctify
  class BidderRegistrationTest < ActiveSupport::TestCase
    attr_reader :auction, :bidder
    setup do
      @auction = auctify_sales(:auction_in_progress)
      @bidder = users(:lucifer)
    end

    test "is pending on create" do
      b_reg = Auctify::BidderRegistration.create(bidder: bidder, auction: auction)

      assert b_reg.persisted?, "Registration is not persisted, errors: #{b_reg.errors.full_messages}"

      assert b_reg.reload.valid?
      assert b_reg.pending?
      assert_equal bidder, b_reg.bidder
      assert_equal auction, b_reg.auction
    end

    test "can be created only for :accepted or :in_sale auction" do
      skip
    end

    test "must have bidder and auction" do
      skip
    end

    test "sets correct dates on processing" do
      skip "submitted_at on submitting"
      # "sets handled_at on handling"
    end
  end
end
