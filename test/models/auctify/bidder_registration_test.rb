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
                        "Aukce aktuálně nepovoluje nové registrace",
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

    test "forbid deleting if there are any bids" do
      b_reg = Auctify::BidderRegistration.create(bidder: bidder, auction: auction)
      assert_includes auction.bidder_registrations, b_reg

      assert auction.bid!(Auctify::Bid.new(registration: b_reg, price: auction.current_price + 1))
      assert b_reg.bids.count.positive?

      assert_not b_reg.destroy
      assert_includes b_reg.errors[:base], "Nemůžu smazat položku protože existuje závislé/ý příhozy", b_reg.errors.to_json

      b_reg.bids.destroy_all
      assert b_reg.bids.count.zero?

      assert b_reg.destroy

      assert_not_includes auction.bidder_registrations.reload, b_reg
    end

    test "fillup autobids" do
      # if two following bids have same visualisation, keep the newest one (with exceptions)
      b_reg1 = auction.bidder_registrations.first
      b_reg2 = auction.bidder_registrations.last
      assert_not_equal b_reg1, b_reg2

      b_reg1.bids.destroy_all
      b_reg2.bids.destroy_all
      assert_equal 0, auction.bids.reload.size

      assert_equal 1_001, auction.current_price

      user_bids = [
        Auctify::Bid.new(max_price: 15_000, registration: b_reg1),
        Auctify::Bid.new(max_price: 17_000, registration: b_reg1),
        # price is still 1_001
        Auctify::Bid.new(price: 3_000, registration: b_reg2),
        # AUTOBID(3_500,17_000) INSERTED! price is now 3_500 (automatic overbidding) for b_reg1
        Auctify::Bid.new(price: 5_000, registration: b_reg1), # b_reg1 is winning by limit but adds direct bid (under own limit)
        # AUTOBID(5_000,17_000) INSERTED!
        Auctify::Bid.new(max_price: 17_000, registration: b_reg2), # same limit as b_reg1, but different bidder
        # AUTOBID(17_000,17_000) INSERTED!
        # b_reg1 is winning with 17_000 (same price , but bid was older then reg2)
        Auctify::Bid.new(price: 18_000, registration: b_reg2),
        # price is now 18_000 for b_reg2
        Auctify::Bid.new(price: 19_000, registration: b_reg1),
        Auctify::Bid.new(max_price: 21_000, registration: b_reg1), # no change in auction.current_price, but setting own limit
        Auctify::Bid.new(max_price: 22_000, registration: b_reg1), # no change in auction.current_price, but increasing own limit
        # price is now 19_000 for b_reg1
        Auctify::Bid.new(price: 21_000, registration: b_reg1), # b_reg1 is winning by limit, but adds direct bid (under limit)
        # AUTOBID(21_000,22_000) INSERTED!
        Auctify::Bid.new(price: 23_000, registration: b_reg1), # b_reg1 is winning by limit, but adds direct bid (above limit)
        # AUTOBID(23_000,22_000) INSERTED!
        Auctify::Bid.new(price: 25_000, registration: b_reg1), # b_reg1 is winning, but still adds another direct bid
        Auctify::Bid.new(price: 27_000, registration: b_reg2),
        Auctify::Bid.new(max_price: 34_000, registration: b_reg2),

        Auctify::Bid.new(max_price: 31_000, registration: b_reg1),
        # AUTOBID(32_000,34_000) INSERTED! b_reg2 winning with 32_000
        Auctify::Bid.new(price: 33_000, registration: b_reg1),
        # AUTOBID(34_000,34_000) INSERTED! b_reg2 winning with 34_000
        Auctify::Bid.new(price: 35_000, registration: b_reg1),
        # AUTOBID(35_000,34_000) INSERTED! b_reg1 winning with 35_000
      ]

      applied_user_bids = []
      Auctify.configuration.stub(:restrict_overbidding_yourself_to_max_price_increasing, false) do
        user_bids.each do |bid|
          assert auction.bid!(bid), "Bid was not appended! #{bid.to_json}, \n errors: #{bid.errors.to_json}"
          applied_user_bids << bid.reload
        end
      end

      assert_equal 35_000, auction.current_price

      autobids = auction.ordered_applied_bids.reload - applied_user_bids

      assert_equal 8, autobids.size # 8 autobids, see comments above
      assert autobids.all? { |b| b.autobid == true }
      assert applied_user_bids.all? { |b| b.autobid == false }

      # now test backward fillup
      Auctify::Bid.where(registration_id: [b_reg1.id, b_reg2.id]).update_all(autobid: false)
      assert auction.ordered_applied_bids.reload.none?(&:autobid)

      b_reg1.fillup_autobid_flags!
      b_reg2.fillup_autobid_flags!

      autobid_ids = auction.ordered_applied_bids.where(autobid: true).pluck(:id)
      non_autobid_ids = auction.ordered_applied_bids.where(autobid: false).pluck(:id)

      assert_not autobid_ids.blank?
      assert_equal autobids.collect(&:id).sort, autobid_ids.sort
      assert_equal applied_user_bids.collect(&:id).sort, non_autobid_ids.sort
    end
  end
end
