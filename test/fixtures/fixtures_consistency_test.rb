# frozen_string_literal: true

require "test_helper"

class FixturesConsistencyTest < ActiveSupport::TestCase
  test "counts" do
    assert_equal %w[Lucifer Eve Adam].sort, User.pluck("name").sort
    assert_equal ["Apple", "Innocence", "Fig leave", "Snake (without apple)", "Flaming sword"].sort,
                 Thing.pluck("name").sort
    assert_equal 5, Auctify::Sale::Base.count # details bellow
    assert_equal 4, Auctify::BidderRegistration.count
  end

  test "Eve's apple" do
    sale = auctify_sales(:eve_apple)
    assert_equal users(:eve), sale.seller
    assert_equal users(:adam), sale.buyer
    assert_equal things(:apple), sale.item
    assert sale.is_a?(Auctify::Sale::Auction)

    assert_equal %w[Adam Lucifer], sale.bidders.pluck(:name)
  end

  test "Adam's innocence" do
    sale = auctify_sales(:adam_innocence)
    assert_equal users(:adam), sale.seller
    assert_nil sale.buyer
    assert_equal things(:innocence), sale.item
    assert sale.is_a?(Auctify::Sale::Retail)
  end

  test "unpublished sale" do
    sale = auctify_sales(:unpublished_sale)
    assert_equal users(:adam), sale.seller
    assert_nil sale.buyer
    assert_equal things(:leaf), sale.item
    assert sale.is_a?(Auctify::Sale::Retail)
    assert_not sale.published?
  end

  test "auction in progress" do
    auction = auctify_sales(:auction_in_progress)
    assert_equal users(:eve), auction.seller
    assert_nil auction.buyer
    assert_equal things(:snake), auction.item
    assert auction.is_a?(Auctify::Sale::Auction)
    assert auction.in_sale?

    assert_equal %w[Adam Lucifer], auction.bidders.pluck(:name)
    assert_equal 2, auction.bids.size
    assert_equal [users(:lucifer), users(:adam)], auction.bids.collect { |b| b.bidder }
  end

  test "future auction" do
    sale = auctify_sales(:future_auction)
    assert_equal users(:eve), sale.seller
    assert_nil sale.buyer
    assert_equal things(:flaming_sword), sale.item
    assert sale.is_a?(Auctify::Sale::Auction)
    assert_not sale.in_sale?
    assert_not sale.published?

    # assert %w[Adam Lucifer], sale.bidders.pluck(:name)
  end
end
