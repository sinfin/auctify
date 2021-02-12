# frozen_string_literal: true

require "test_helper"

class UserTest < ActiveSupport::TestCase
  test "can sell things (as seller)" do
    seller = users(:eve)
    thing = seller.things.first
    assert thing.present?

    sale = seller.sell(thing, in: :auction, price: 1000)

    assert seller.sales.reload.include?(sale)
    assert thing.sales.reload.include?(sale)

    assert_equal thing, sale.item
    assert_equal seller, sale.seller
    skip
    # assert_equal 1000, sale.auction_price
    # assert sale.is_a?(Auctify::Sale::Auction)
  end
end
