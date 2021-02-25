# frozen_string_literal: true

module Auctify
  class BidsAppender < ServiceBase
    attr_reader :auction, :bid

    def initialize(auction:, bid: nil)
      super()
      @auction = auction
      @bid = bid
    end

    def build_result
      self.current_price = auction.current_price
      @updated_win_bid = nil

      if bid
        set_price_for_bid if bid.price.blank? && bid.with_limit?

        if approved_bid?
          solve_winner(winning_bid, bid)
          append_bids!
        else
          fail!
        end
      end

      @result = result_struct
    end

    private
      attr_accessor :current_price

      def result_struct
        OpenStruct.new(
          current_price: current_price,
          current_minimal_bid: new_current_minimal_bid,
          winning_bid: winning_bid
        )
      end

      def set_price_for_bid
        if bid.max_price <= new_current_minimal_bid
          bid.price = bid.max_price
        else
          bid.price = new_current_minimal_bid
        end
      end

      def approved_bid?
        @approved_bid ||= approve_bid
      end

      def approve_bid
        check_price_minimum
        check_same_bidder
        check_auction_state
        check_bid_registration_to_auction

        errors.add_from_hash(bid.errors.to_hash)

        errors.empty?
      end

      def append_bids!
        # saving first, so it will still be winning even if both have same price
        if @updated_win_bid.present?
          fail! unless @updated_win_bid.save
        end

        fail! unless bid.save

        @winning_bid = nil
        @bids = auction.bids.reload

        auction.current_price = new_current_price
        fail! unless auction.save
        self.current_price = auction.current_price
      end

      def new_current_price
        winning_bid.price
      end

      def new_current_minimal_bid
        return current_price if first_bid?

        increase_price(current_price)
      end

      def winning_bid
        @winning_bid ||= auction.bids.ordered.first # or should I go by the price?
      end

      def first_bid?
        bids.empty?
      end

      def bids
        @bids ||= auction.bids
      end

      def check_price_minimum
        bid.errors.add(:price, :price_is_bellow_current) if bid.price < current_price
        bid.errors.add(:price, :price_is_bellow_current) if bid.price == current_price && !first_bid?
        bid.errors.add(:price, :price_is_bellow_minimal_bid) if bid.price < new_current_minimal_bid
      end

      def check_same_bidder
        if winning_bid.present? && (winning_bid.bidder == bid.bidder)
          bid.errors.add(:bidder, :you_cannot_overbid_yourself)
        end
      end

      def check_auction_state
        unless auction.in_sale?
          bid.errors.add(:auction, :auction_is_not_accepting_bids_now)
        end
      end

      def check_bid_registration_to_auction
        if bid.registration.auction != auction
          bid.errors.add(:auction, :bidder_is_not_registered_for_this_auction)
        end
      end

      def solve_winner(winning_bid, new_bid)
        return if winning_bid.blank?

        solve_limits_fight(winning_bid, new_bid)          if  bid.with_limit? &&  winning_bid.with_limit?
        increase_bid_price(winning_bid, new_bid)          if  bid.with_limit? && !winning_bid.with_limit?
        duplicate_increased_win_bid(winning_bid, new_bid) if !bid.with_limit? &&  winning_bid.with_limit?
        # do nothing, all is solved already               if !bid.with_limit? && !winning_bid.with_limit?
      end

      def solve_limits_fight(winning_bid, new_bid)
        if winning_bid.max_price < new_bid.max_price
          new_bid.price = increase_price_to(overcome: winning_bid.max_price, ceil: new_bid.max_price)
        else
          new_bid.price = new_bid.max_price
          update_winning_bid_to(increase_price_to(overcome: new_bid.max_price, ceil: winning_bid.max_price))
        end
      end

      def increase_bid_price(winning_bid, new_bid)
        if winning_bid.price < new_bid.max_price
          new_bid.price = increase_price_to(overcome: winning_bid.price, ceil: new_bid.max_price)
        else
          new_bid.price = new_bid.max_price
        end
      end

      def duplicate_increased_win_bid(winning_bid, new_bid)
        if winning_bid.max_price < new_bid.price
          update_winning_bid_to(winning_bid.max_price)
        else
          update_winning_bid_to(increase_price_to(overcome: new_bid.price, ceil: winning_bid.max_price))
        end
      end

      def update_winning_bid_to(price)
        @updated_win_bid = winning_bid.dup
        @updated_win_bid.price = [price, winning_bid.max_price].min
      end

      def increase_price(price)
        return price + 1 if bid_steps_ladder.blank?

        _range, increase_step = bid_steps_ladder.detect { |range, step| range.cover?(price) }
        price + increase_step
      end

      def increase_price_to(overcome:, ceil:)
        return ceil if overcome == ceil
        raise ":ceil is lower than :ovecome" if ceil < overcome

        running_price = current_price
        while running_price <= overcome
          running_price = increase_price(running_price)
        end

        return running_price if running_price <= ceil

        raise "Runing price overcome the ceil price!"
      end

      def bid_steps_ladder
        @bid_steps_ladder ||= auction.bid_steps_ladder
      end
  end
end
