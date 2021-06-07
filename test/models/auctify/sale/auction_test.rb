# frozen_string_literal: true

require "test_helper"

module Auctify
  module Sale
    class AuctionTest < ActiveSupport::TestCase
      attr_reader :auction
      include Auctify::AuctionHelpers

      test "take auctioneer_commission from itself, sale_pack or config" do
        auction = Auctify::Sale::Auction.new(sold_price: 10_000)
        assert auction.commission_in_percent.blank?
        assert auction.pack.blank?

        assert_equal 1, Auctify.configuration.auctioneer_commission_in_percent

        assert_equal auction.sold_price * 0.01, auction.auctioneer_commission

        auction.pack = Auctify::SalesPack.new(commission_in_percent: 5)

        assert_equal auction.sold_price * 0.05, auction.auctioneer_commission

        assert auction.commission_in_percent = 33

        assert_equal auction.sold_price * 0.33, auction.auctioneer_commission
      end

      test "no commision when not sold" do
        auction = Auctify::Sale::Auction.new(commission_in_percent: 50)

        assert_nil auction.sold_price

        assert_nil auction.auctioneer_commission

        auction.sold_price = 10_000

        assert_equal 5_000, auction.auctioneer_commission
      end



      test "current_price adapts according to offered_price until first bid" do
        offered_price = 1_000
        new_offered_price = offered_price + 2_000
        adam = users(:adam)

        auction = auctify_sales(:accepted_auction)
        auction.update!(offered_price:  offered_price)

        auction.bidder_registrations.approved.create!(bidder: adam)
        allow_bids_for([adam], auction)

        assert_equal offered_price, auction.offered_price
        assert_nil auction.current_price

        auction.start_sale!

        assert_equal offered_price, auction.offered_price
        assert_equal offered_price, auction.current_price

        auction.offered_price = new_offered_price
        assert auction.save

        assert_equal new_offered_price, auction.offered_price
        assert_equal new_offered_price, auction.current_price

        bid = bid_for(adam, 5_000)
        assert auction.reload.bid!(bid)

        assert_equal 1, auction.ordered_applied_bids.reload.size

        assert_not auction.update(offered_price: (new_offered_price + 42))

        assert_includes auction.errors[:offered_price], "Již není možné měnit vyvolávací cenu"
        assert_equal new_offered_price, auction.offered_price
        assert_equal bid.price, auction.current_price
      end

      test "currently_ends_at adapts according to ends_at until first bid" do
        ends_at = Time.current + 1.hour
        ends_at_new = ends_at + 1.day
        adam = users(:adam)

        auction = auctify_sales(:accepted_auction)
        auction.update!(ends_at:  ends_at)

        auction.bidder_registrations.approved.create(bidder: adam)
        allow_bids_for([adam], auction)

        assert_equal ends_at, auction.ends_at
        assert_nil auction.currently_ends_at

        auction.start_sale!

        assert_equal ends_at, auction.ends_at
        assert_equal ends_at, auction.currently_ends_at

        auction.ends_at = ends_at_new
        assert auction.save

        assert_equal ends_at_new, auction.ends_at
        assert_equal ends_at_new, auction.currently_ends_at

        assert auction.reload.bid!(bid_for(adam, 2_000))

        assert_equal 1, auction.ordered_applied_bids.reload.size

        assert_not auction.update(ends_at: (ends_at_new + 2.days))

        assert_includes auction.errors[:ends_at], "Již není možné měnit čas konce aukce"
        assert_equal ends_at_new.to_i, auction.ends_at.to_i
        assert_equal ends_at_new.to_i, auction.currently_ends_at.to_i
      end

      test "recalculating can handle 'no_bids_left'" do
        auction = auctify_sales(:auction_in_progress)
        assert_equal 2, auction.applied_bids_count
        assert_not_equal auction.offered_price, auction.current_price

        auction.ordered_applied_bids.each do |bid|
          bid.cancel! # which calls recalculating
        end

        assert auction.reload.applied_bids_count.zero?
        assert auction.ordered_applied_bids.count.zero?
        assert_equal auction.offered_price, auction.current_price
      end

      test "forbid deleting if there are any bids" do
        auction = auctify_sales(:auction_in_progress)
        assert_equal 2, auction.applied_bids_count

        assert_not auction.destroy
        assert_includes auction.errors[:base], "Není možné mazat aukční položku, která má příhozy", auction.errors.to_json

        auction.bidder_registrations.each { |br| br.bids.destroy_all }
        assert auction.bids.count.zero?

        assert_difference("Auctify::BidderRegistration.count", (-1 * auction.bidder_registrations.size)) do
          assert auction.destroy
        end
      end
    end
  end
end
