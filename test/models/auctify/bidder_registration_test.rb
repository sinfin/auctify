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
      allowed = %i[in_sale accepted]
      (auction.aasm.states.collect(&:name) - allowed).each do |state|
        auction.aasm_state = state
        b_reg = Auctify::BidderRegistration.create(bidder: bidder, auction: auction)

        assert_includes b_reg.errors[:auction],
                        "Aukce aktuálně neupovoluje nové registrace",
                        "creating registration for state '#{state}' " \
                          "should be forbidden, errors: #{b_reg.errors.full_messages}"
      end

      allowed.each do |state|
        auction.aasm_state = state
        b_reg = Auctify::BidderRegistration.create(bidder: bidder, auction: auction)

        assert b_reg.persisted?, "Registration is not persisted for auction in state '#{state}'," \
                                    " errors: #{b_reg.errors.full_messages}"
      end
    end

    test "must have bidder" do
      b_reg = Auctify::BidderRegistration.create(bidder: nil, auction: auction)

      assert_not b_reg.persisted?
      assert_includes b_reg.errors[:bidder], "musí existovat"
    end

    test "must have auction" do
      b_reg = Auctify::BidderRegistration.create(bidder: bidder, auction: nil)
      assert_not b_reg.persisted?
      assert_includes b_reg.errors[:auction], "musí existovat"
    end

    test "sets correct dates on processing" do
      b_reg = Auctify::BidderRegistration.create(bidder: bidder, auction: auction)
      assert b_reg.pending?

      assert_nil b_reg.handled_at

      b_reg.approve!

      assert b_reg.approved?
      assert b_reg.handled_at.present?
      assert b_reg.handled_at <= Time.current

      b_reg.unapprove!

      assert b_reg.pending?
      assert_nil b_reg.handled_at

      b_reg.reject!

      assert b_reg.rejected?
      assert b_reg.handled_at.present?
      assert b_reg.handled_at <= Time.current
    end
  end
end
