# frozen_string_literal: true

module Auctify
  module Sale
    class Auction < Auctify::Sale::Base
      include AASM

      attr_accessor :winning_bid

      has_many :bidder_registrations, dependent: :destroy
      has_many :bids, through: :bidder_registrations, dependent: :destroy

      aasm do
        state :offered, initial: true, color: "red"
        state :accepted, color: "red"
        state :refused, color: "dark"
        state :in_sale, color: "yellow"
        state :bidding_ended, color: "yellow"
        state :auctioned_successfully, color: "green"
        state :auctioned_unsuccessfully, color: "red"
        state :sold, color: "green"
        state :not_sold, color: "dark"
        state :cancelled, color: "red"

        event :accept_offer do
          transitions from: :offered, to: :accepted
        end

        event :refuse_offer do
          transitions from: :offered, to: :refused
        end

        event :start_sale do
          before do
            self.current_price = self.offered_price
            self.buyer = nil
          end

          transitions from: :accepted, to: :in_sale
        end

        event :close_bidding do
          transitions from: :in_sale, to: :bidding_ended
        end

        event :sold_in_auction do
          transitions from: :bidding_ended, to: :auctioned_successfully, if: :valid?

          before do |*args| # TODO: sold_at
            params = args.first # expecting keys :buyer, :price
            self.buyer = params[:buyer]
            self.sold_price = params[:price]
          end
        end

        event :not_sold_in_auction do
          transitions from: :bidding_ended, to: :auctioned_unsuccessfully, if: :no_winner?
        end

        event :sell do
          transitions from: :auctioned_successfully, to: :sold
        end

        event :end_sale do
          transitions from: :auctioned_unsuccessfully, to: :not_sold
        end

        event :cancel do
          transitions from: [:offered, :accepted], to: :cancelled
        end
      end

      validate :buyer_vs_bidding_consistence

      def bidders
        @bidders ||= bidder_registrations.collect { |br| br.bidder }.sort_by(&:name)
      end

      def bid!(bid)
        ActiveRecord::Base.transaction do
          bap = Auctify::BidsAppender.call(auction: self, bid: bid)
          return true if bap.success?
          # errors can be in `bid.errors` or as `bap.errors`
          return false
        end
      end

      def winning_bid
        bidding_final_result.winning_bid
      end

      def bidding_final_result
        Auctify::BidsAppender.call(auction: self, bid: nil).result
      end

      def opening_price
        offered_price
      end

      private
        def buyer_vs_bidding_consistence
          return true if buyer.blank? && sold_price.blank?

          unless buyer == bidding_final_result.winner
            errors.add(:buyer,
                       :buyer_is_not_the_winner,
                       buyer: buyer.to_label,
                       winner: bidding_final_result.winner.to_label)
          end

          unless sold_price == bidding_final_result.won_price
            errors.add(:sold_price,
                       :sold_price_is_not_from_bidding,
                       sold_price: sold_price,
                       won_price: bidding_final_result.won_price)
          end
        end

        def no_winner?
          return true if bidding_final_result.winner.blank?
          errors.add(:buyer,
            :there_is_a_buyer_for_not_sold_auction,
             winner: bidding_final_result.winner.to_label)
          false
        end
    end
  end
end

# == Schema Information
#
# Table name: auctify_sales
#
#  id               :integer          not null, primary key
#  aasm_state       :string           default("offered"), not null
#  bid_steps_ladder :json
#  buyer_type       :string
#  current_price    :decimal(, )
#  item_type        :string           not null
#  offered_price    :decimal(, )
#  published_at     :datetime
#  reserve_price    :decimal(, )
#  seller_type      :string           not null
#  selling_price    :decimal(, )
#  sold_price       :decimal(, )
#  type             :string           default("Auctify::Sale::Base")
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#  buyer_id         :integer
#  item_id          :integer          not null
#  seller_id        :integer          not null
#
# Indexes
#
#  index_auctify_sales_on_buyer_type_and_buyer_id    (buyer_type,buyer_id)
#  index_auctify_sales_on_item_type_and_item_id      (item_type,item_id)
#  index_auctify_sales_on_seller_type_and_seller_id  (seller_type,seller_id)
#
