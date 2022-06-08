# frozen_string_literal: true

Yabeda.configure do
  group :auctify do
    gauge :bids_count,
           comment: "A count of all applied bids"
    # counter :bids_count, comment: "A count of all applied bids"
    gauge :time_between_last_bids_seconds,
          comment: "Time period between last two manual bids"
    gauge :current_max_delay_in_closing_auction_seconds,
          comment: "Delay from oldest `currently_ends_at` of auction in sale (that should be already closed).",
          tags: [:auction_slug]

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

    auction = Auctify::Sale::Auction.in_sale.order(currently_ends_at: :asc).first
    delay = [0, (Time.current - auction.currently_ends_at)].max
    auctify.current_max_delay_in_closing_auction_seconds.set({ auction_slug: auction.slug }, delay)
  end
end
