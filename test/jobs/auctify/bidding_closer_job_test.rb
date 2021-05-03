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
      assert_enqueued_jobs 1, only: job_class do
        auction.start_sale!
      end

      # should be set to run at auction.currently_ends_at
      enq_job = ActiveJob::Base.queue_adapter.enqueued_jobs.last

      assert_equal auction.id, enq_job["arguments"].first["auction_id"]
      assert_equal auction.id, enq_job[:args].first["auction_id"]
      assert_equal auction.currently_ends_at.to_i, enq_job[:at].to_i
    end

    test "closes bidding when auction.currently_ends_at passed" do
      assert_enqueued_jobs 1, only: job_class do
        auction.start_sale!
      end

      Time.stub(:current, auction.currently_ends_at) do
        assert auction.reload.in_sale?
        perform_enqueued_jobs(only: job_class)
        assert auction.reload.bidding_ended?
      end
    end

    test "enqueue itself again in currently_ends_at was changed" do
      assert_enqueued_jobs 1, only: job_class do
        auction.start_sale!
      end
      enqueued_at = auction.currently_ends_at
      puts("enqued first to #{enqueued_at}")
      auction.update!(currently_ends_at: enqueued_at + 1.second)

      skip "Code bellow works but creates new job again and immediatelly performs it, "\
           "because it is the same job class as in `perform_enqueued_jobs(only: job_class)`" \
           "Rails 6.1 add option :at which shouls help"
      # see https://blog.saeloun.com/2020/02/17/rails-6-1-adds-at-option-to-perform_enqueued_jobs-test-helper.html

      Time.stub(:current, enqueued_at) do
        assert auction.reload.in_sale?
        assert_enqueued_jobs 1, only: job_class do
          perform_enqueued_jobs(only: job_class)
        end
        assert auction.reload.in_sale?
      end

      new_enq_job = ActiveJob::Base.queue_adapter.enqueued_jobs.last
      assert_equal auction.currently_ends_at.to_i, new_enq_job[:at].to_i
    end

    test "takes queue name from config" do
      skip "TODO"
    end

    def job_class
      ::Auctify::BiddingCloserJob
    end
  end
end
