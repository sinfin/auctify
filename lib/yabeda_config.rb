# frozen_string_literal: true

Yabeda.configure do
  group :auctify do
    gauge :bids_count, comment: "A count of all applied bids"
    # counter :bids_count, comment: "A count of all applied bids"
    gauge :time_between_last_bids_seconds, comment: "Time period between last two manual bids"

    # this is done in job
    gauge :diff_in_closing_time_seconds,
          comment: "Difference between auction.currently_ends_at and actual sale end time by job"
  end

  # to fetch correct data independently on process/container
  # we collect them at request for /metrics, not at "trigger" time
  collect do # when /metrics is displayed
    auctify.bids_count.set({}, Auctify::Bid.count)

    last_bid_times = Auctify::Bid.applied.manual.order(created_at: :desc).limit(2).pluck(:created_at)
    auctify.time_between_last_bids_seconds.set({}, last_bid_times.size == 2 ? last_bid_times.first - last_bid_times.last : 0)
  end
end
