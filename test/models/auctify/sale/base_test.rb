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

      test "validates optional seller" do
        assert sale.valid?

        sale.seller = nil

        assert sale.valid?
      end

      test "if seller is appended, must be auctified and present" do
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
        assert_equal ["musí existovat"], sale.errors[:item]

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

        assert_not sale.publish!

        sale.offered_price = 1
        assert sale.publish!

        assert sale.reload.published?
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

      test "validate prices" do
        assert sale.valid?
        sale.offered_price = -1
        assert_not sale.valid?
        sale.offered_price = 1
        assert sale.valid?
      end

      test "validate offered_price when published" do
        assert sale.valid?
        sale.published = true
        assert_not sale.valid?
        assert_equal :required_for_published, sale.errors.details[:offered_price].first[:error]

        sale.offered_price = 1
        assert sale.valid?
      end

      test "fill bid_steps_ladder for auctions from config, if not set" do
        ladder = { 0...10 => 1, 10...100 => 5, 100.. => 10 }
        specific_ladder = { 0...1_000 => 10, 1_000.. => 100 }
        default_ladder = { 0.. => 1 }

        assert_equal default_ladder, Auctify::Sale::Auction.new.bid_steps_ladder

        Auctify.configure { |c| c.default_bid_steps_ladder = ladder }

        assert_equal ladder, Auctify::Sale::Auction.new.bid_steps_ladder
        assert_equal specific_ladder, Auctify::Sale::Auction.new(bid_steps_ladder: specific_ladder).bid_steps_ladder

        assert_equal ladder, Auctify::Sale::Auction.create!(item: things(:apple), ends_at: Time.current + 1.hour).reload.bid_steps_ladder

        Auctify.configure { |c| c.default_bid_steps_ladder = default_ladder }
      end

      test "have scope .latest_published_by_item" do
        apple = things(:apple)
        assert_equal 1, apple.sales.reload.size
        fixture_sale = apple.sales.first
        assert fixture_sale.auctioned_successfully?

        assert_includes Auctify::Sale::Base.latest_published_by_item, fixture_sale

        latest_sale = Auctify::Sale::Base.create!(seller: users(:adam), item: apple, offered_price: 555)

        lpbi_sales = Auctify::Sale::Base.latest_published_by_item

        # latest is not yet published!
        assert_includes lpbi_sales, fixture_sale
        assert_not_includes lpbi_sales, latest_sale

        assert latest_sale.publish!

        lpbi_sales = Auctify::Sale::Base.latest_published_by_item

        assert_not_includes lpbi_sales, fixture_sale
        assert_includes lpbi_sales, latest_sale
      end
    end
  end
end
