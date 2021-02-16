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
      assert SellerTestUser.new(name: "Krutibrko").respond_to?(:sell)
    end

    test "#sell allow to sell only auctified items" do
      sale = users(:adam).sell(things(:apple), in: :auction, price: 1_000)
      assert sale.is_a?(Auctify::Sale::Base)

      # TODO: `assert_raises(Auctify::NonAuctifiedItem) do`
      assert_raises(RuntimeError) do
        users(:adam).sell(CleanThing.new, in: :auction, price: 1_000)
      end
    end
  end
end
