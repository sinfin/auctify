# frozen_string_literal: true

require "test_helper"

module Auctify
  class BiddingCloserJobTest < ActiveSupport::TestCase
    attr_reader :auction

    include Auctify::AuctionHelpers
    include ActiveJob::TestHelper

    setup do
      @auction = auctify_sales(:accepted_auction)
      @auction.start_sale!
    end

    test "closes bidding when auction.currently_ends_at passed when not closing manually" do
      Time.stub(:current, auction.currently_ends_at) do
        assert auction.reload.in_sale?

        job_class.perform_now(auction_id: auction.id)

        assert auction.reload.bidding_ended?
      end
    end

    test "do not enqueue itself again if currently_ends_at was changed" do # this is done by EnsureSalesClosingJob
      assert_enqueued_jobs 0, only: job_class

      enqueued_at = auction.currently_ends_at
      job_class.set(wait_until: enqueued_at).perform_later(auction_id: auction.id)

      assert_enqueued_jobs 1, only: job_class

      auction.update!(currently_ends_at: enqueued_at + 1.second)

      Time.stub(:current, enqueued_at) do
        assert auction.reload.in_sale?

        perform_enqueued_jobs(only: job_class)

        assert auction.reload.in_sale?
        assert_enqueued_jobs 0, only: job_class
      end
    end

    def job_class
      ::Auctify::BiddingCloserJob
    end
  end
end
