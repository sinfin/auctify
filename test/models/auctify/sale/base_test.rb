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

        assert_equal ["musí existovat"], sale.errors[:item]

        item_not_in_db = Thing.new(id: (Thing.order(id: :desc).pick(:id) + 1))
        sale.item = item_not_in_db

        assert sale.invalid?
        assert_equal ["musí existovat", "musí existovat"], sale.errors[:item] # TODO remove duplication

        non_auctified_item = CleanThing.first
        assert non_auctified_item.present?

        sale.item = non_auctified_item
        assert sale.invalid?
        assert_equal ["objekt Předmětu nebyl Auctifikován pomocí `auctify_as: :item`", "musí existovat"], sale.errors[:item]
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


      test "can be published immediatelly" do
        assert_not sale.published?

        sale.publish!

        assert sale.reload.published?
        assert sale.published_at <= Time.current
      end

      test "can be published from selected time" do
        assert_not sale.published?

        publish_at = Time.current + 2.seconds
        sale.publish_from(publish_at)


        assert_not sale.published?
        assert sale.published_at = publish_at

        sleep 2
        assert sale.published?
      end

      test "can be build from form params with auctify_ids" do
        seller = users(:eve)
        buyer = users(:adam)
        item = things(:apple)

        sale = Auctify::Sale::Base.new(seller_auctify_id: seller.auctify_id,
                                       buyer_auctify_id: buyer.auctify_id,
                                       item_auctify_id: item.auctify_id)

        assert_equal seller, sale.seller
        assert_equal buyer, sale.buyer
        assert_equal item, sale.item
      end

      test "sets currently_ands_at" do
        d1 = Time.current + 1.day
        d2 = Time.current + 2.days
        d3 = Time.current + 3.days
        d4 = Time.current + 4.days
        d5 = Time.current + 5.days

        sale = Auctify::Sale::Base.new

        assert_nil sale.ends_at
        assert_nil sale.currently_ends_at

        sale.update(ends_at: d1)

        assert_equal d1, sale.ends_at
        assert_equal d1, sale.currently_ends_at

        sale.update(ends_at: d2)

        assert_equal d2, sale.ends_at
        assert_equal d2, sale.currently_ends_at

        sale.update(currently_ends_at: d4) # change on bid close to ends_at

        assert_equal d2, sale.ends_at
        assert_equal d4, sale.currently_ends_at

        sale.update(ends_at: d3)

        assert_equal d3, sale.ends_at
        assert_equal d4, sale.currently_ends_at

        sale.update(ends_at: d5)

        assert_equal d5, sale.ends_at
        assert_equal d5, sale.currently_ends_at
      end
    end
  end
end
