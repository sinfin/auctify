# frozen_string_literal: true

require "test_helper"

module Auctify
  module Sale
    class AuctionStatesTest < ActiveSupport::TestCase
      attr_reader :auction

      setup do
        @auction = Auctify::Sale::Auction.new(seller: users(:eve), item: things(:apple), offered_price: 123.4)

        assert @auction.valid?, "auction is not valid! : #{@auction.errors.full_messages}"
      end

      test "have initial state 'offered'" do
        assert auction.offered?
      end

      test "can be refused" do
        auction.refuse_offer

        assert auction.refused?
      end

      test "can be canceled before acception" do
        auction.cancel

        assert auction.cancelled?
      end

      test "can be canceled before start selling" do
        auction.accept_offer

        assert auction.accepted?

        auction.cancel

        assert auction.cancelled?
      end

      test "cannot be canceled after start selling" do
        auction.accept_offer

        assert auction.accepted?

        auction.start_sale

        assert auction.in_sale?

        assert_raises(AASM::InvalidTransition) do
          auction.cancel
        end

        assert auction.in_sale?

        auction.close_bidding

        assert auction.bidding_ended?

        auction.sold_in_auction(buyer: users(:adam), price: 1_234)

        assert_raises(AASM::InvalidTransition) do
          auction.cancel
        end

        assert auction.auctioned_successfully?
      end

      test "can be sold" do
        auction.accept_offer

        assert auction.accepted?

        offered_price = auction.offered_price
        assert_nil auction.current_price

        auction.start_sale

        assert auction.in_sale?
        assert_equal offered_price, auction.offered_price
        assert_equal offered_price, auction.current_price

        auction.close_bidding

        assert auction.bidding_ended?

        auction.sold_in_auction(buyer: users(:adam), price: 1_234)

        assert auction.auctioned_successfully?
        assert_equal users(:adam), auction.buyer
        assert_equal 1_234.00, auction.sold_price

        auction.sell

        assert auction.sold?
      end

      test "can be not_sold" do
        auction.accept_offer

        assert auction.accepted?

        auction.start_sale

        assert auction.in_sale?

        auction.close_bidding

        assert auction.bidding_ended?

        auction.not_sold_in_auction

        assert auction.auctioned_unsuccessfully?

        auction.end_sale # nobody buy it

        assert auction.not_sold?
      end

      test "cannot be auctioned if not in sale" do
        auction.accept_offer

        assert auction.accepted?

        assert_raises(AASM::InvalidTransition) do
          auction.sold_in_auction(buyer: users(:adam), price: 1_234)
        end

        assert auction.accepted?
        assert auction.buyer.blank?
        assert_nil auction.sold_price

        assert_raises(AASM::InvalidTransition) do
          auction.not_sold_in_auction
        end

        assert auction.accepted?
        assert auction.buyer.blank?
        assert_nil auction.sold_price
      end
    end
  end
end
