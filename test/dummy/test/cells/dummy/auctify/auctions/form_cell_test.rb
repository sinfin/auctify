# frozen_string_literal: true

require "test_helper"

class Dummy::Auctify::Auctions::FormCellTest < Cell::TestCase
  test "show" do
    auction = auctify_sales(:auction_in_progress)
    html = cell("dummy/auctify/auctions/form", auction).(:show)
    assert html.has_css?(".d-au-auctions-form")
  end
end
