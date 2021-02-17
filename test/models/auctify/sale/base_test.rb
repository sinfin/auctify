# frozen_string_literal: true

require "test_helper"

module Auctify
  module Sale
    class SaleTest < ActiveSupport::TestCase
      attr_reader :sale

      setup do
        @sale = Auctify::Sale::Base.new(seller: users(:eve), item: things(:apple))

        assert @sale.valid?, "Valid_sale is not valid! : #{@sale.errors.full_messages}"
      end

      test "validates seller" do
        assert sale.valid?

        sale.seller = nil

        assert sale.invalid?
        assert_equal ["musí existovat", "musí existovat"], sale.errors[:seller]

        user_not_in_db = User.new(id: (User.order(id: :desc).pick(:id) + 1))
        sale.seller = user_not_in_db

        assert sale.invalid?
        assert_equal ["musí existovat"], sale.errors[:seller]

        non_auctified_user = CleanUser.first
        assert non_auctified_user.present?

        sale.seller = non_auctified_user

        assert sale.invalid?
        assert_equal ["objekt Prodejce nebyl Auctifikován pomocí `auctify_as: :seller`"], sale.errors[:seller]
      end

      test "validates item" do
        assert sale.valid?

        sale.item = nil

        assert sale.invalid?
        assert_equal ["musí existovat", "musí existovat"], sale.errors[:item]

        item_not_in_db = Thing.new(id: (Thing.order(id: :desc).pick(:id) + 1))
        sale.item = item_not_in_db

        assert sale.invalid?
        assert_equal ["musí existovat"], sale.errors[:item]

        non_auctified_item = CleanThing.first
        assert non_auctified_item.present?

        sale.item = non_auctified_item
        assert sale.invalid?
        assert_equal ["objekt Předmětu nebyl Auctifikován pomocí `auctify_as: :item`"], sale.errors[:item]
      end

      test "validates buyer if present" do
        assert sale.valid?

        sale.buyer = nil

        assert sale.valid?

        user_not_in_db = User.new(id: (User.order(id: :desc).pick(:id) + 1))
        sale.buyer = user_not_in_db

        assert sale.invalid?
        assert_equal ["musí existovat"], sale.errors[:buyer]

        non_auctified_user = CleanUser.first
        assert non_auctified_user.present?

        sale.buyer = non_auctified_user

        assert sale.invalid?
        assert_equal ["objekt Kupce nebyl Auctifikován pomocí `auctify_as: :buyer`"], sale.errors[:buyer]
      end
    end
  end
end
