# frozen_string_literal: true

require "test_helper"

module Auctify
  module Sale
    class ReatilTest < ActiveSupport::TestCase
      attr_reader :sale

      setup do
        @sale = Auctify::Sale::Retail.new(seller: users(:eve), item: things(:apple))

        assert @sale.valid?, "Valid_sale is not valid! : #{@sale.errors.full_messages}"
      end

      test "have initial state 'offered'" do
        assert sale.offered?
      end

      test "can be refused" do
        sale.refuse_offer

        assert sale.refused?
      end

      test "can be canceled before acception" do
        sale.cancel

        assert sale.cancelled?
      end

      test "can be canceled before start selling" do
        sale.accept_offer

        assert sale.accepted?

        sale.cancel

        assert sale.cancelled?
      end

      test "cannot be canceled after start selling" do
        sale.accept_offer

        assert sale.accepted?

        sale.start_sale

        assert sale.in_sale?

        assert_raises(AASM::InvalidTransition) do
          sale.cancel
        end

        assert sale.in_sale?

        sale.sell(buyer: users(:adam), price: 1_234)

        assert sale.sold?
        assert_equal users(:adam), sale.buyer
        assert_equal 1_234.00, sale.sold_price

        assert_raises(AASM::InvalidTransition) do
          sale.cancel
        end

        assert sale.sold?
      end

      test "can be sold" do
        sale.accept_offer

        assert sale.accepted?

        sale.start_sale

        assert sale.in_sale?

        sale.sell(buyer: users(:adam), price: 1_234)

        assert sale.sold?
        assert_equal users(:adam), sale.buyer
        assert_equal 1_234.00, sale.sold_price
      end

      test "can be not_sold" do
        sale.accept_offer

        assert sale.accepted?

        sale.start_sale

        assert sale.in_sale?

        sale.end_sale # nobody buy it

        assert sale.not_sold?
      end

      test "cannot be sold if not in sale" do
        sale.accept_offer

        assert sale.accepted?

        assert_raises(AASM::InvalidTransition) do
          sale.sell(buyer: users(:adam), price: 1_234)
        end

        assert sale.accepted?
        assert sale.buyer.blank?
        assert_nil sale.sold_price
      end
    end
  end
end
