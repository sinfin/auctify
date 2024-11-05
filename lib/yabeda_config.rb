# frozen_string_literal: true

Yabeda.configure do
  group :auctify do
    gauge :bids_count,
           comment: "A count of all applied bids"
    # counter :bids_count, comment: "A count of all applied bids"
    gauge :time_between_last_bids_seconds,
          comment: "Time period between last two manual bids"
    gauge :bids_per_minute,
          comment: "New bids in last minute"

    gauge :current_max_delay_in_closing_auction_seconds,
          comment: "Delay from oldest `currently_ends_at` of auction in sale (that should be already closed)."


    # this is done when auction.close_bidding! is run
    gauge :diff_in_closing_time_seconds,
          comment: "Difference between auction.currently_ends_at and actual sale end time by job"
  end

  # to fetch correct data independently on process/container
  # we collect them at request for /metrics, not at "trigger" time
  collect do # when /metrics is displayed
    auctify.bids_count.set({}, Auctify::Bid.count)

    last_bids = Auctify::Bid.applied.manual.order(created_at: :desc) # .select(:created_at).to_a
    last_2_bids_created_at = last_bids.first(2).pluck(:created_at).to_a
    diff = last_2_bids_created_at.size > 1 ? (last_2_bids_created_at.first - last_2_bids_created_at.second).round : 0
    auctify.time_between_last_bids_seconds.set({}, diff)

    last_minute_bids_count = last_bids.where("created_at > ? ", 1.minute.ago).count
    auctify.bids_per_minute.set({}, last_minute_bids_count)

    auction = Auctify::Sale::Auction.in_sale.order(currently_ends_at: :asc).first
    if auction.blank?
      auctify.current_max_delay_in_closing_auction_seconds.set({}, -1)
    else
      delay = [0, (Time.current - auction.currently_ends_at)].max # only positive number
      auctify.current_max_delay_in_closing_auction_seconds.set({}, delay.round)
    end
  end
end
