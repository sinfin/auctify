# frozen_string_literal: true

require "test_helper"

module Auctify
  module Sale
    class AuctionStatesTest < ActiveSupport::TestCase
      attr_reader :auction, :registrations

      include Auctify::AuctionHelpers

      setup do
        @auction = Auctify::Sale::Auction.new(seller: users(:eve),
                                   item: things(:apple),
                                   offered_price: 123.4,
                                   ends_at: Time.current + 1.hour)

        assert @auction.valid?, "auction is not valid! : #{@auction.errors.full_messages}"
        assert_nil auction.buyer
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
        assert_nil auction.buyer

        assert_raises(AASM::InvalidTransition) do
          auction.cancel
        end

        assert auction.in_sale?

        auction.close_bidding

        assert auction.bidding_ended?
        assert_nil auction.buyer

        appender_result = OpenStruct.new(won_price: 1_000, winner: users(:adam))
        Auctify::BidsAppender.stub(:call, OpenStruct.new(result: appender_result)) do
          auction.sold_in_auction(buyer: users(:adam), price: 1_000)
        end

        assert_equal users(:adam), auction.buyer

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
        assert_nil auction.currently_ends_at

        auction.start_sale

        assert auction.in_sale?
        assert_equal offered_price, auction.offered_price
        assert_equal offered_price, auction.current_price
        assert_equal auction.ends_at, auction.currently_ends_at
        assert_equal 1, auction.callback_runs[:after_start_sale]

        auction.close_bidding

        assert auction.bidding_ended?
        assert_equal 1, auction.callback_runs[:after_close_bidding]

        appender_result = OpenStruct.new(won_price: 1_000, winner: users(:adam))
        Auctify::BidsAppender.stub(:call, OpenStruct.new(result: appender_result)) do
          auction.sold_in_auction(buyer: users(:adam), price: 1_000)
        end

        assert auction.auctioned_successfully?
        assert_equal users(:adam), auction.buyer
        assert_equal 1_000.00, auction.sold_price
        assert_equal 1, auction.callback_runs[:after_sold_in_auction]

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
        assert_equal 1, auction.callback_runs[:after_not_sold_in_auction]

        auction.end_sale # nobody buy it

        assert auction.not_sold?
        assert_nil auction.buyer
      end

      test "cannot be auctioned if not in sale" do
        auction.accept_offer

        assert auction.accepted?

        assert_raises(AASM::InvalidTransition) do
          auction.sold_in_auction(buyer: users(:adam), price: 1_234)
        end

        assert auction.accepted?

        assert_raises(AASM::InvalidTransition) do
          auction.not_sold_in_auction
        end

        assert auction.accepted?
      end

      test "nullify buyer on start_sale" do
        auction = auctify_sales(:accepted_auction)
        auction.buyer = users(:adam)

        auction.start_sale

        assert_nil auction.buyer
      end

      test "validate winner and price on sold_in_auction event" do
        @registrations = { users(:adam) => auction.bidder_registrations.detect { |r| r.bidder == users(:adam) } }

        auction.accept_offer
        auction.start_sale
        auction.close_bidding
        assert auction.bidding_ended?

        appender_result = OpenStruct.new(won_price: 1_000, winner: users(:adam))

        Auctify::BidsAppender.stub(:call, OpenStruct.new(result: appender_result)) do
          assert_raises(AASM::InvalidTransition) do
            auction.sold_in_auction(buyer: users(:lucifer), price: 1_000)
          end
          assert auction.bidding_ended?
          assert_includes auction.errors[:buyer], "Kupec Lucifer není výhercem aukce, tím je Adam"

          assert_raises(AASM::InvalidTransition) do
            auction.sold_in_auction(buyer: users(:adam), price: 1_001)
          end
          assert auction.bidding_ended?
          assert_includes auction.errors[:sold_price], "Prodejní cena 1001.0 neodpovídá výherní ceně z aukce 1000"

          auction.sold_in_auction(buyer: users(:adam), price: 1_000)
          assert auction.auctioned_successfully?
        end
      end

      test "validate no-winner on not_sold_in_auction event" do
        @registrations = { users(:adam) => auction.bidder_registrations.detect { |r| r.bidder == users(:adam) } }

        auction.accept_offer
        auction.start_sale
        auction.close_bidding
        assert auction.bidding_ended?

        Auctify::BidsAppender.stub(:call, OpenStruct.new(result: OpenStruct.new(won_price: 1_000, winner: users(:adam)))) do
          assert_raises(AASM::InvalidTransition) do
            auction.not_sold_in_auction
          end
          assert auction.bidding_ended?
          assert_includes auction.errors[:buyer], "Aukci nelze označit za neprodanou, neboť má kupce (Adam)"
        end

        Auctify::BidsAppender.stub(:call, OpenStruct.new(result: OpenStruct.new(won_price: nil, winner: nil))) do
          auction.not_sold_in_auction
          assert auction.auctioned_unsuccessfully?
        end
      end

      test "when published is set to true, sale starts immediatelly (for offered auction)" do
        auction.published = false

        assert_not auction.in_sale?
        assert auction.offered?

        auction.published = true

        assert auction.in_sale?
      end

      test "when published is set to true, sale starts immediatelly (for accepted auction)" do
        auction.accept_offer

        auction.published = false

        assert_not auction.in_sale?
        assert auction.accepted?

        auction.published = true

        assert auction.in_sale?
      end
    end
  end
end
