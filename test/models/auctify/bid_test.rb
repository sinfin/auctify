# frozen_string_literal: true

require "test_helper"

module Auctify
  class BidTest < ActiveSupport::TestCase
    test "requires rounded prices" do
      registration = Auctify::BidderRegistration.new
      bid = Auctify::Bid.new(price: 100, max_price: nil, registration: registration)

      # rounding is set by configuration, default is 1
      Auctify.configuration.stub(:require_bids_to_be_rounded_to, 100) do
        assert bid.valid?, bid.errors.full_messages

        bid.price = 123

        assert_not bid.valid?
        assert_includes bid.errors[:price], "musí být zaokrouhlená na celé 100 Kč"

        bid.price = 1100
        bid.max_price = 1200

        assert bid.valid?, bid.errors.full_messages

        bid.max_price = 1230

        assert_not bid.valid?
        assert_includes bid.errors[:max_price], "musí být zaokrouhlená na celé 100 Kč"
      end

      Auctify.configuration.stub(:require_bids_to_be_rounded_to, 10) do
        bid.max_price = 1230
        assert bid.valid?
      end
    end

    test "sorting" do
      t = Time.current - 10.minutes
      bid3 = Auctify::Bid.new(price: 100, max_price: nil, id: 5, created_at: t + 1.second)
      bid2 = Auctify::Bid.new(price: 100, max_price: nil, id: 3, created_at: t + 1.second)
      bid4 = Auctify::Bid.new(price: 100, max_price: nil, id: 4, created_at: t + 2.second)
      bid1 = Auctify::Bid.new(price: 100, max_price: nil, id: 2, created_at: t + 1.second)
      bid5 = Auctify::Bid.new(price: 200, max_price: nil, id: 10, created_at: t + 1.second)
      expected_ordered_bids = [bid1, bid2, bid3, bid4, bid5]
      # sorting order price ASC, created_at ASC, id ASC
      assert_equal expected_ordered_bids, expected_ordered_bids.reverse.shuffle.sort
    end
  end
end
