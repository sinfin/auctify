# frozen_string_literal: true

require "test_helper"

class FixturesConsistencyTest < ActiveSupport::TestCase
  test "counts" do
    assert_equal %w[Lucifer Eve Adam].sort, User.pluck("name").sort
    assert_equal ["Apple", "Innocence", "Fig leave", "Magic ball", "Naughty fun", "Snake (without apple)", "Rabbit (without handgranade)", "Flaming sword"].sort,
                 Thing.pluck("name").sort
    assert_equal 8, Auctify::Sale::Base.count # details bellow
    assert_equal 9, Auctify::BidderRegistration.count
    assert_equal 3, Auctify::SalesPack.count
    assert_equal 2, auctify_sales_packs(:things_from_eden).sales.count
    assert_equal 3, auctify_sales_packs(:published_pack).sales.count
  end

  test "all records are valid" do
    [Auctify::SalesPack, Auctify::Sale::Base, Auctify::Bid, Auctify::BidderRegistration].each do |klass|
      klass.all.each { |record| assert record.valid?, "NOT VALID: #{klass} #{record.to_json} => #{record.errors.full_messages}" }
    end
  end

  test "Eve's apple" do
    sale = auctify_sales(:eve_apple)
    assert_equal users(:eve), sale.seller
    assert_equal users(:adam), sale.buyer
    assert_equal users(:adam), sale.winner
    assert_equal things(:apple), sale.item
    assert sale.is_a?(Auctify::Sale::Auction)
    assert sale.auctioned_successfully?
    assert_equal auctify_sales_packs(:things_from_eden), sale.pack
    assert_equal sale.ordered_applied_bids.count, sale.applied_bids_count

    assert_equal %w[Adam Lucifer], sale.bidders.pluck(:name)
  end

  test "Adam's innocence" do
    sale = auctify_sales(:adam_innocence)
    assert_equal users(:adam), sale.seller
    assert_nil sale.buyer
    assert_equal users(:eve), sale.winner
    assert_equal things(:innocence), sale.item
    assert sale.is_a?(Auctify::Sale::Auction)
    assert sale.bidding_ended?
    assert_equal auctify_sales_packs(:things_from_eden), sale.pack
    assert_equal sale.ordered_applied_bids.count, sale.applied_bids_count

    assert_equal %w[Eve Lucifer], sale.bidders.pluck(:name)
  end

  test "unpublished sale" do
    sale = auctify_sales(:unpublished_sale)
    assert_equal users(:adam), sale.seller
    assert_nil sale.buyer
    assert_equal things(:leaf), sale.item
    assert sale.is_a?(Auctify::Sale::Retail)
    assert_not sale.published?
    assert_nil sale.pack
  end

  test "auction in progress" do
    auction = auctify_sales(:auction_in_progress)
    assert_equal users(:eve), auction.seller
    assert_nil auction.buyer
    assert_equal things(:snake), auction.item
    assert auction.is_a?(Auctify::Sale::Auction)
    assert auction.in_sale?
    assert_equal 10, auction.offered_price
    assert_equal 101, auction.current_price
    assert_equal auction.winning_bid.price, auction.current_price
    assert_not_nil auction.ends_at
    assert_equal auction.ends_at, auction.currently_ends_at
    assert_equal auctify_sales_packs(:published_pack), auction.pack
    assert_equal auction.ordered_applied_bids.count, auction.applied_bids_count

    assert_equal %w[Adam Lucifer], auction.bidders.pluck(:name)
    assert_equal 2, auction.bids.size
    assert_equal [users(:adam), users(:lucifer)].sort, auction.bids.ordered.collect { |b| b.bidder }.sort
  end

  test "future auction" do
    sale = auctify_sales(:future_auction)
    assert_equal users(:eve), sale.seller
    assert_nil sale.buyer
    assert_equal things(:flaming_sword), sale.item
    assert sale.is_a?(Auctify::Sale::Auction)
    assert_not sale.in_sale?
    assert_not sale.published?
    assert_equal auctify_sales_packs(:published_pack), sale.pack

    # assert %w[Adam Lucifer], sale.bidders.pluck(:name)
  end

  test "accepted auction" do
    sale = auctify_sales(:accepted_auction)
    assert_equal users(:eve), sale.seller
    assert_nil sale.buyer
    assert_equal things(:fun), sale.item
    assert sale.is_a?(Auctify::Sale::Auction)
    assert sale.accepted?
    assert_nil sale.pack

    assert_equal %w[Adam Lucifer], sale.bidders.pluck(:name)
  end

  test "sale without seller" do
    sale = auctify_sales(:sale_without_seller)
    assert_nil sale.seller
    assert_nil sale.buyer
    assert_equal things(:magic_ball), sale.item
    assert sale.is_a?(Auctify::Sale::Auction)
    assert sale.offered?
    assert_nil sale.pack
  end
end
