# frozen_string_literal: true

require "test_helper"

module Auctify
  class EnsureAuctionsClosingJobTest < ActiveSupport::TestCase
    attr_reader :time_now,
                :old_open_auction,
                :old_closed_auction,
                :now_ending_auction,
                :now_ending_closed_auction,
                :auction_ending_in_1_second,
                :auction_ending_at_the_end_of_time_frame,
                :auction_ending_after_time_frame,
                :pack

    include ActiveJob::TestHelper

    setup do
      @time_now = Time.current
      interval = Auctify.configuration.auction_prolonging_limit_in_seconds

      @pack = Auctify::SalesPack.create!(title: "EnsureAuctionsClosingJob pack",
                                         start_date: 1.day.ago,
                                         end_date: 1.day.from_now,
                                         published: true)

      @old_open_auction = create_open_auction_ending_at(time_now - 1.second)
      @old_closed_auction = create_open_auction_ending_at(time_now - 1.second)
      @old_closed_auction.update!(aasm_state: :bidding_ended)

      @now_ending_auction = create_open_auction_ending_at(time_now)
      @now_ending_closed_auction = create_open_auction_ending_at(time_now)
      @now_ending_closed_auction.update!(aasm_state: :bidding_ended)

      @auction_ending_in_1_second = create_open_auction_ending_at(time_now + 1.second)
      @auction_ending_at_the_end_of_time_frame = create_open_auction_ending_at(time_now + interval)
      @auction_ending_after_time_frame = create_open_auction_ending_at(time_now + interval + 1.second)
    end

    test "creates BiddingCloserJobs for future close-to-end auctions" do
      assert_enqueued_jobs 0, only: job_class

      expected_enqueued_auctions = [
        auction_ending_in_1_second,
        auction_ending_at_the_end_of_time_frame
      ]

      Time.stub(:current, time_now) do
        job_class.perform_now

        assert_enqueued_closing_jobs_for(expected_enqueued_auctions)
      end
    end

    test "skips BiddingCloserJobs for manually-closed future close-to-end auctions" do
      assert_enqueued_jobs 0, only: job_class

      pack.update!(sales_closed_manually: true)

      Time.stub(:current, time_now) do
        job_class.perform_now
      end

      assert_enqueued_jobs 0, only: job_class
    end

    test "creates BiddingCloserJobs for auctions which should be closed now already" do
      assert_enqueued_jobs 0, only: job_class

      expected_immediatelly_performed_auctions = [
        old_open_auction,
        now_ending_auction
      ]

      Time.stub(:current, time_now) do
        job_class.perform_now

        perform_enqueued_jobs
        assert_performed_closing_jobs_for(expected_immediatelly_performed_auctions)
      end
    end

    test "respects Auctify.configuration.auction_prolonging_limit_in_seconds for lookup" do
      lookup_end_time = time_now + Auctify.configuration.auction_prolonging_limit_in_seconds
      assert lookup_end_time < auction_ending_after_time_frame.currently_ends_at
      assert auction_ending_at_the_end_of_time_frame.currently_ends_at <= lookup_end_time

      assert_enqueued_jobs 0, only: job_class

      expected_enqueued_auctions = [
        auction_ending_in_1_second,
        auction_ending_at_the_end_of_time_frame
      ]

      Time.stub(:current, time_now) do
        job_class.perform_now

        assert_enqueued_closing_jobs_for(expected_enqueued_auctions)
      end


      old_prolonging_limit = Auctify.configuration.auction_prolonging_limit_in_seconds
      Auctify.configure { |conf|  conf.auction_prolonging_limit_in_seconds += 10.seconds }

      lookup_end_time = time_now + Auctify.configuration.auction_prolonging_limit_in_seconds
      assert auction_ending_after_time_frame.currently_ends_at < lookup_end_time

      expected_enqueued_auctions = [
        auction_ending_in_1_second,
        auction_ending_at_the_end_of_time_frame,
        auction_ending_after_time_frame
      ]

      Time.stub(:current, time_now) do
        job_class.perform_now

        assert_enqueued_closing_jobs_for(expected_enqueued_auctions)
      end

      Auctify.configure { |conf|  conf.auction_prolonging_limit_in_seconds = old_prolonging_limit }
    end

    private
      def job_class
        ::Auctify::EnsureAuctionsClosingJob
      end

      def create_open_auction_ending_at(time)
        a = Auctify::Sale::Auction.create!(ends_at: time, item: Thing.create!(name: "thing"), pack: pack)
        a.accept_offer
        a.start_sale!
        a
      end

      def assert_enqueued_closing_jobs_for(auctions)
        auctions.each do |auction|
          assert_enqueued_with(job: Auctify::BiddingCloserJob, at: auction.currently_ends_at, args: [auction_id: auction.id])
        end
      end

      def assert_performed_closing_jobs_for(auctions)
        auctions.each do |auction|
          assert auction.reload.bidding_ended?
          # assert_performed_with(job: Auctify::BiddingCloserJob, args: [auction_id: auction.id])
        end
      end
  end
end
