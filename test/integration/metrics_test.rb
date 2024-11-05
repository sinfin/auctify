# frozen_string_literal: true

require "test_helper"

module Auctify
  class MetricsTest < ActionDispatch::IntegrationTest
    attr_reader :metrics

    include Auctify::AuctionHelpers

    setup do
      check_initial_metrics
    end

    test "current_max_delay_in_closing_auction_seconds metric" do
      auction = auctify_sales(:accepted_auction)

      assert_metric("current_max_delay_in_closing_auction_seconds 0.0") # auction_in_progress

      auction.start_sale!

      assert_metric("current_max_delay_in_closing_auction_seconds 0.0")

      auction.currently_ends_at = Time.now - 1.minute
      auction.save!

      assert_metric("current_max_delay_in_closing_auction_seconds 60.0")

      Auctify::Sale::Auction.in_sale.each { |a| a.close_bidding! }

      assert_metric("current_max_delay_in_closing_auction_seconds -1.0") # no auction in sale
    end

    test "time_between_last_bids_seconds + bids_count metric" do
      auction = auctify_sales(:auction_in_progress)
      lucifer = users(:lucifer)
      adam = users(:adam)
      @registrations = auction.bidder_registrations.index_by { |reg| reg.bidder }

      assert_equal [adam, lucifer], auction.bidders
      initial_bids_count = Auctify::Bid.count

      l_bid = bid_for(lucifer, 1_001)
      a_bid = bid_for(adam, 1_101)
      t1 = Time.current + 1.second
      t2 = Time.current + 43.seconds
      diff = (t2 - t1).round

      assert_metric("auctify_bids_count #{initial_bids_count}")
      assert_metric("auctify_bids_per_minute #{initial_bids_count}")

      Time.stub(:current, t1) { assert auction.bid!(l_bid) }
      Time.stub(:current, t2) { assert auction.bid!(a_bid) }

      assert_metric("auctify_time_between_last_bids_seconds #{diff}")
      assert_metric("auctify_bids_count #{initial_bids_count + 2}")
      assert_metric("auctify_bids_per_minute #{initial_bids_count + 2}")
    end

    test "auctify_diff_in_closing_time_seconds" do
      auction = auctify_sales(:auction_in_progress)

      t1 = Time.current + 1.second
      t2 = Time.current + 43.seconds
      auction.currently_ends_at = t1
      assert auction.save

      Time.stub(:current, t2) { auction.close_bidding! }

      assert_not auction.in_sale?
      assert_metric("auctify_diff_in_closing_time_seconds #{(t2 - t1).round}")
    end

    private
      def check_initial_metrics
        get_metrics

        assert metrics.include?("auctify_bids_count #{Auctify::Bid.count.to_f}")
        assert metrics.include?("time_between_last_bids_seconds 0.0"), metrics
        assert metrics.include?("current_max_delay_in_closing_auction_seconds 0.0"), metrics
        assert metrics.include?("auctify_diff_in_closing_time_seconds"), metrics
      end

      def get_metrics
        get "/metrics"
        @metrics = response.body
      end

      def assert_metric(expected)
        assert get_metrics.include?(expected), "Expected \n#{metrics} \n\n to include '#{expected}'"
      end
  end
end
