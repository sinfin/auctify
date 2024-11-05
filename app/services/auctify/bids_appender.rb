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
        set_price_for_limit_bid

        if approved_bid?
          solve_winner(winning_bid, bid)
          append_bids!
          update_auction! unless failed?
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
          winning_bid: winning_bid,
          winner: winner,
          won_price: (overcame_reserve_price? ? current_price : nil)
        )
      end

      def set_price_for_limit_bid
        return unless bid.price.blank? && bid.with_limit?

        if changing_own_limit_when_winning?
          bid.price = [bid.max_price, winning_bid.price].min
        elsif bid.max_price <= new_current_minimal_bid
          bid.price = bid.max_price
        else
          bid.price = new_current_minimal_bid
        end
      end

      def approved_bid?
        @approved_bid ||= begin
          bid.valid?
          check_bidder
          check_max_price_increasing
          check_price_minimum
          check_price_maximum
          check_same_bidder
          check_auction_state

          errors.add_from_hash(bid.errors.to_hash)

          errors.empty?
        end
      end

      def append_bids!
        fail! unless bid.save

        # saving last, so it will still be winning, even if both have same price
        if @updated_win_bid.present?
          fail! unless @updated_win_bid.save
        end
      end

      def update_auction!
        @winning_bid = nil
        @bids = bids.reload


        fail! unless auction.succesfull_bid!(price: new_current_price,
                                             winner: winner,
                                             time: bid.reload.created_at)
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
        @winning_bid ||= bids.first
      end

      def winner
        (overcame_reserve_price? ? winning_bid.bidder : nil)
      end

      def overcame_reserve_price?
        return false if winning_bid.blank?
        return false if auction.reserve_price.present? && auction.current_price < auction.reserve_price

        true
      end

      def first_bid?
        winning_bid.nil?
      end

      def bids
        @bids ||= auction.ordered_applied_bids
      end

      def check_bidder
        unless bid.registration&.auction == auction
          bid.errors.add(:auction, :bidder_is_not_registered_for_this_auction)
        end
        unless auction.bidding_allowed_for?(bid.bidder)
          bid.errors.add(:bidder, :you_are_not_allowed_to_bid)
        end
      end

      def check_max_price_increasing
        return unless changing_own_limit_when_winning?

        bid.errors.add(:bidder, :you_can_only_increase_your_max_price) if bid.max_price.to_i <= winning_bid.max_price.to_i
      end

      def check_price_minimum
        minimum = changing_own_limit_when_winning? ? current_price : new_current_minimal_bid
        if bid.price < minimum
          att = bid.with_limit? ? :max_price : :price
          bid.errors.add(att,
                         :price_is_bellow_minimal_bid,
                         minimal_bid: ActionController::Base.helpers.number_to_currency(new_current_minimal_bid, precision: 0))
        end
      end

      def check_price_maximum
        return if bid.with_limit?

        maximum = Auctify.configuration.maximal_increase_of_price_proc.call(auction)
        return if maximum.blank?

        if maximum < bid.price
          bid.errors.add(:price,
                         :too_high_price_increase,
                         max_allowed_price: ActionController::Base.helpers.number_to_currency(maximum, precision: 0))
        end
      end

      def check_same_bidder
        return if overbidding_yourself_allowed? || changing_own_limit_when_winning?

        if winning_bid.present? && same_bidder?(winning_bid, bid)
          bid.errors.add(:bidder, :you_cannot_overbid_yourself)
        end
      end

      def check_auction_state
        # comparing time with seconds precision, use `.to_i`
        return if auction.in_sale? && bid.created_at.to_i <= auction.currently_ends_at.to_i

        bid.errors.add(:auction, :auction_is_not_accepting_bids_now)
      end

      def solve_winner(winning_bid, new_bid)
        return if winning_bid.blank? || changing_own_limit_when_winning?

        solve_limits_fight(winning_bid, new_bid)          if  new_bid.with_limit? &&  winning_bid.with_limit?
        increase_bid_price(winning_bid, new_bid)          if  new_bid.with_limit? && !winning_bid.with_limit?
        duplicate_increased_win_bid(winning_bid, new_bid) if !new_bid.with_limit? &&  winning_bid.with_limit?
        # do nothing, all is solved already               if !bid.with_limit? && !winning_bid.with_limit?
      end

      def solve_limits_fight(winning_bid, new_bid)
        if winning_bid.max_price < new_bid.max_price
          update_winning_bid_to(winning_bid.max_price)
          new_bid.price = [new_bid.price, increase_price_to(overcome: winning_bid.max_price, ceil: new_bid.max_price)].max
        else
          new_bid.price = new_bid.max_price
          update_winning_bid_to(increase_price_to(overcome: new_bid.max_price, ceil: winning_bid.max_price))
        end
      end

      def increase_bid_price(winning_bid, new_bid)
        if winning_bid.price < new_bid.max_price
          new_bid.price = [new_bid.price, increase_price_to(overcome: winning_bid.price, ceil: new_bid.max_price)].max
        else
          new_bid.price = new_bid.max_price
        end
      end

      def duplicate_increased_win_bid(winning_bid, new_bid)
        if winning_bid.max_price < new_bid.price
          update_winning_bid_to(winning_bid.max_price)
        elsif overbidding_yourself_allowed? && same_bidder?(winning_bid, new_bid)
          update_winning_bid_to(new_bid.price, force_if_equal: true)
        else
          update_winning_bid_to(increase_price_to(overcome: new_bid.price, ceil: winning_bid.max_price))
        end
      end

      def update_winning_bid_to(price, force_if_equal: false)
        return if price < winning_bid.price
        return if price == winning_bid.price && !force_if_equal

        @updated_win_bid = winning_bid.dup
        @updated_win_bid.price = [price, winning_bid.max_price].min
        @updated_win_bid.autobid = true
      end

      def increase_price(price)
        price + auction.minimal_bid_increase_amount_at(price, respect_first_bid: false)
      end

      def increase_price_to(overcome:, ceil:)
        return ceil if overcome == ceil
        raise ":ceil is lower than :overcome" if ceil < overcome

        running_price = current_price
        while running_price <= overcome
          running_price = increase_price(running_price)
        end

        [running_price, ceil].min
      end

      def changing_own_limit_when_winning?
        bid.with_limit? && winning_bid.present? && (winning_bid.bidder == bid.bidder)
      end

      def overbidding_yourself_allowed?
        Auctify.configuration.restrict_overbidding_yourself_to_max_price_increasing == false
      end

      def same_bidder?(winning_bid, new_bid)
        winning_bid.bidder == new_bid.bidder
      end
  end
end
