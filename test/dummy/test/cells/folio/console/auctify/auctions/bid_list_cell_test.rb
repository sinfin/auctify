# frozen_string_literal: true

require "test_helper"

class Folio::Console::Auctify::Auctions::BidListCellTest < Cell::TestCase
  test "show" do
    html = cell("folio/console/auctify/auctions/bid_list", nil).(:show)
    assert html.has_css?(".f-c-au-auctions-bid-list")
  end
end
