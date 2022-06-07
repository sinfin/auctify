# frozen_string_literal: true

require "yabeda/prometheus"

Yabeda.configure do
  group :auctify do
   counter :bids_count, comment: "A counter of applied bids"
   gauge :diff_in_closing_time_seconds,
          comment: "Difference between auction.currently_ends_at and actual sale end time by job"
   gauge :time_between_bids, comment: "Time period between last two bids", tags: [:auction_slug]
 end

  collect do # when /metrics is displayed
    # main_app.t_gauge.set({}, rand(10))
  end
end
