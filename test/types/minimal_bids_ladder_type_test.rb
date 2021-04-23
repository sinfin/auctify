# frozen_string_literal: true

require "test_helper"

module Auctify
  class MinimalBidsLadderlTypeTest < ActiveSupport::TestCase
    attr_reader :auction

    setup do
      @auction = Auctify::Sale::Auction.new(seller: users(:eve), item: things(:apple), offered_price: 123.4)
    end

    test "it can store ranged hash" do
      auction.bid_steps_ladder = minimal_bids_as_ranges
      auction.save!
      auction.reload

      assert_equal app_usage_version, auction.bid_steps_ladder
      assert_equal JSON.parse(db_store_version), JSON.parse(auction.read_attribute_before_type_cast("bid_steps_ladder"))
    end

    test "it can store min prices as strings" do
      auction.bid_steps_ladder = minimal_bids_by_strings
      auction.save!
      auction.reload

      assert_equal app_usage_version, auction.bid_steps_ladder
      assert_equal JSON.parse(db_store_version), JSON.parse(auction.read_attribute_before_type_cast("bid_steps_ladder"))
    end

    test "it can store min_prices as numbers" do
      auction.bid_steps_ladder = minimal_bids_by_numbers
      auction.save!
      auction.reload

      assert_equal app_usage_version, auction.bid_steps_ladder
      assert_equal JSON.parse(db_store_version), JSON.parse(auction.read_attribute_before_type_cast("bid_steps_ladder"))
    end

    test "it can store min_prices from json" do
      auction.bid_steps_ladder = minimal_bids_in_json
      auction.save!
      auction.reload

      assert_equal app_usage_version, auction.bid_steps_ladder
      assert_equal JSON.parse(db_store_version), JSON.parse(auction.read_attribute_before_type_cast("bid_steps_ladder"))
    end

    private
      def app_usage_version
        minimal_bids_as_ranges
      end

      def db_store_version
        Hash[minimal_bids_by_strings.to_a.sort_by { |step| step.first.to_i }].to_json
      end

      def minimal_bids_as_ranges
        {
          (0...5_000) => 100,
          (5_000...20_000) => 500,
          (20_000...100_000) => 1_000,
          (100_000...500_000) => 5_000,
          (500_000...1_000_000) => 10_000,
          (1_000_000...2_000_000) => 50_000,
          (2_000_000..) => 100_000
        }
      end

      def minimal_bids_by_strings
        {
          "0" => 100,
          "5_000" => 500,
          "20_000" => 1_000,
          "1_000_000" => 50_000,
          "100_000" => 5_000,
          "500_000" => 10_000,
          "2_000_000" => 100_000
        }
      end

      def minimal_bids_by_numbers
        {
          500_000 => 10_000,
          0 => 100,
          5_000 => 500,
          2_000_000 => 100_000,
          20_000 => 1_000,
          100_000 => 5_000,
          1_000_000 => 50_000
        }
      end

      def minimal_bids_in_json
        minimal_bids_by_strings.to_json
      end
  end
end
