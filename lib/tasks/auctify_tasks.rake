# frozen_string_literal: true

namespace :auctify do
  desc "Fill in missing auctions.bid_steps_ladders"
  task fill_misssing_bid_steps_ladders: :environment do
    default_ladder = Auctify::Sale::Auction.new.bid_steps_ladder
    Auctify::Sale::Auction.where(bid_steps_ladder: nil).find_each do |asa|
      unless asa.update(bid_steps_ladder: default_ladder)
        puts("ERROR '#{asa.errors.full_messages}' on update of #{asa.to_json}")
      end
    end
  end


  desc "Fix current_price and currently_ends_at for in_sale auctions without bids"
  task fix_auction_dependent_attributes: :environment do
    Auctify::Sale::Auction.in_sale.where(applied_bids_count: 0).find_each do |asa|
      unless asa.update(current_price: asa.offered_price, currently_ends_at: asa.ends_at)
        puts("ERROR '#{asa.errors.full_messages}' on update of #{asa.to_json}")
      end
    end
  end
end
