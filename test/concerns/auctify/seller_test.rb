# frozen_string_literal: true

require "test_helper"

module Auctify
  class SellerTest < ActiveSupport::TestCase
    setup do
      class SellerTestUser < CleanUser; end # so it will not propagate class_eval to User class
    end

    test " adds `sales` association" do
      assert_not SellerTestUser.new(name: "Krutibrko").respond_to?(:sales)

      SellerTestUser.class_eval do
        auctify_as :seller
      end

      assert SellerTestUser.new(name: "Krutibrko").respond_to?(:sales)
      assert SellerTestUser.new(name: "Krutibrko").respond_to?(:offer_to_sale!)
    end

    test "#sell allow to sell only auctified items" do
      sale = users(:adam).offer_to_sale!(things(:apple), in: :auction, price: 1_000)
      assert sale.is_a?(Auctify::Sale::Base)

      exc = assert_raises(ActiveRecord::RecordInvalid) do
        users(:adam).offer_to_sale!(CleanThing.first, in: :auction, price: 1_000)
      end
      assert_equal("Validace je neúspešná: Item objekt Předmětu nebyl Auctifikován pomocí `auctify_as: :item`",
                   exc.message)
    end
  end
end
