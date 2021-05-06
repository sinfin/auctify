# frozen_string_literal: true

require "test_helper"

module Auctify
  class BiddingIsCloseToEndNotifierJobTest < ActiveSupport::TestCase
    attr_reader :auction, :configured_period, :notify_time

    include Auctify::AuctionHelpers
    include ActiveJob::TestHelper

    setup do
      @auction = auctify_sales(:accepted_auction)
      @configured_period = Auctify.configuration.when_to_notify_bidders_before_end_of_bidding
      @notify_time = @auction.ends_at - configured_period
    end

    test "is started on auction.start_sale event" do
      assert_enqueued_jobs 1, only: job_class do
        auction.start_sale!
      end

      # should be set to run at auction.ends_at - configured period
      enq_job = (ActiveJob::Base.queue_adapter.enqueued_jobs.select { |jb_h| jb_h["job_class"] == job_class.name }).last

      assert_equal auction.id, enq_job["arguments"].first["auction_id"]
      assert_equal auction.id, enq_job[:args].first["auction_id"]
      assert_equal notify_time.to_i, enq_job[:at].to_i
    end

    test "calls auction.before_bidding_is_close_to_end when notify_time passed" do
      assert_enqueued_jobs 1, only: job_class do
        auction.start_sale!
      end
      skip "auction.callback_runs are not stored in db, but Job loads new auction instance from DB. How to verify it?"
      Time.stub(:current, notify_time) do
        assert_equal 0, auction.callback_runs[:before_bidding_is_close_to_end]
        perform_enqueued_jobs(only: job_class)
        assert_equal 1, auction.callback_runs[:before_bidding_is_close_to_end]
      end
    end

    test "enqueue itself again if otify time did not pass yet" do
      assert_enqueued_jobs 1, only: job_class do
        auction.start_sale!
      end

      skip "Code bellow works but creates new job again and immediatelly performs it, "\
      "because it is the same job class as in `perform_enqueued_jobs(only: job_class)`" \
      "Rails 6.1 add option :at which should help"
      # see https://blog.saeloun.com/2020/02/17/rails-6-1-adds-at-option-to-perform_enqueued_jobs-test-helper.html

      Time.stub(:current, notify_time - 1.minute) do
        assert_equal 0, auction.callback_runs[:before_bidding_is_close_to_end]
        assert_enqueued_jobs 1, only: job_class do
          perform_enqueued_jobs(only: job_class)
        end
        assert_equal 0, auction.callback_runs[:before_bidding_is_close_to_end]
      end

      new_enq_job = ActiveJob::Base.queue_adapter.enqueued_jobs.last
      assert_equal notify_time.to_i, new_enq_job[:at].to_i
    end

    test "takes queue name from config" do
      skip "TODO"
    end

    def job_class
      ::Auctify::BiddingIsCloseToEndNotifierJob
    end
  end
end
