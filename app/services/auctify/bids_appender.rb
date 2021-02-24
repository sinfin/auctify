# frozen_string_literal: true

module Auctify
  class BidsAppender < ServiceBase
    attr_reader :auction, :bid
    def initialize(auction:, bid: nil)
      @auction = auction
      @bid = bid
    end

    def build_result
      self.current_price = auction.current_price

      append_bid! if bid && approved_bid?

      @result = OpenStruct.new(
        current_price: current_price,
        current_minimal_bid: new_current_minimal_bid,
        winning_bid: winning_bid
      )
    end

    private
      attr_accessor :current_price

      def approved_bid?
        @approved_bid ||= approve_bid
      end

      def approve_bid
        return false if bid.price <= current_price
        return false if winning_bid.present? && (winning_bid.bidder == bid.bidder)
        return false unless auction.in_sale?
        return false if bid.registration.auction != auction

        true
      end

      def append_bid!
        fail! unless bid.save

        auction.current_price = new_current_price
        fail! unless auction.save

        self.current_price = auction.current_price
        @winning_bid = bid
        @bids = auction.bids.reload
      end


      def new_current_price
        bid.price
      end

      def new_current_minimal_bid
        return current_price if first_bid?

        current_price + 1
      end

      def winning_bid
        @winning_bid ||= auction.bids.order(created_at: :desc).first # or should I go by the price?
      end

      def first_bid?
        bids.empty?
      end

      def bids
        @bids ||= auction.bids
      end
  end
end
