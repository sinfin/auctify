# frozen_string_literal: true

require "test_helper"

module Auctify
  class BiddingCloserJobTest < ActiveSupport::TestCase
    attr_reader :auction, :registrations

    include Auctify::AuctionHelpers
    include ActiveJob::TestHelper

    setup do
      @auction = auctify_sales(:accepted_auction)
    end

    test "is started on auction.start_sale event" do
      assert_enqueued_jobs 1, only: ::Auctify::BiddingCloserJob do
        auction.start_sale
      end
      # should be set to run at auction.currently_ends_at
      enq_job = ActiveJob::Base.queue_adapter.enqueued_jobs.last

      assert_equal auction.id, enq_job["arguments"].first["auction_id"]
      assert_equal auction.id, enq_job[:args].first["auction_id"]
      assert_equal auction.currently_ends_at.to_i, enq_job[:at].to_i
    end

    test "takes queue name from config" do
      skip "TODO"
    end
  end
end
