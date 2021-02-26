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
      assert SellerTestUser.new(name: "Krutibrko").respond_to?(:auctions)
      assert SellerTestUser.new(name: "Krutibrko").respond_to?(:offer_to_sale!)
    end

    test "#offer_to_sale allow to sell only auctified items" do
      sale = users(:adam).offer_to_sale!(things(:apple), in: :auction, price: 1_000)
      assert sale.is_a?(Auctify::Sale::Base)

      exc = assert_raises(ActiveRecord::RecordInvalid) do
        users(:adam).offer_to_sale!(CleanThing.first, in: :auction, price: 1_000)
      end
      assert_equal("Validace je neúspešná: Zboží objekt Předmětu nebyl Auctifikován pomocí `auctify_as: :item`",
                   exc.message)
    end

    test "#offer_to_sale checks that seller is owner" do
      skip "is this required?"
    end

    test "#offer_to_sale with `in: auction` option creates Auction" do
      seller = users(:adam)
      thing = things(:innocence)

      sale = seller.offer_to_sale!(thing, in: :auction, price: 1000)

      assert_equal Auctify::Sale::Auction, sale.class
      assert seller.sales.reload.include?(sale)
      assert thing.sales.reload.include?(sale)

      assert_equal thing, sale.item
      assert_equal seller, sale.seller
      assert_equal 1_000, sale.offered_price
    end

    test "#offer_to_sale without `in: auction` option creates Sale::Retail" do
      seller = users(:adam)
      thing = things(:innocence)

      sale = seller.offer_to_sale!(thing, price: 1000)

      assert_equal Auctify::Sale::Retail, sale.class
      assert seller.sales.reload.include?(sale)
      assert thing.sales.reload.include?(sale)

      assert_equal thing, sale.item
      assert_equal seller, sale.seller
      assert_equal 1_000, sale.offered_price
    end

    test "knows its #auctify_id" do
      seller = users(:adam)
      assert_equal "#{seller.class.name}@#{seller.id}", seller.auctify_id
    end
  end
end
