# frozen_string_literal: true

require "yabeda/prometheus/mmap"

Yabeda.configure do
  group :auctify do
    # gauge :bids_count, comment: "A count of all applied bids"
    counter :bids_count, comment: "A count of all applied bids"
    gauge :diff_in_closing_time_seconds,
          comment: "Difference between auction.currently_ends_at and actual sale end time by job"
    gauge :time_between_bids, comment: "Time period between last two bids", tags: [:auction_slug]
  end

  # to fetch correct data independently on process/container
  # we collect them at request for /metrics, not at "trigger" time
  collect do # when /metrics is displayed
    # auctify.bids_count.set({}, Auctify::Bid.count)
  end
end
