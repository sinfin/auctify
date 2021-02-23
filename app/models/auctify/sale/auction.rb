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
          end

          transitions from: :accepted, to: :in_sale
        end

        event :close_bidding do
          transitions from: :in_sale, to: :bidding_ended
        end

        event :sold_in_auction do
          transitions from: :bidding_ended, to: :auctioned_successfully

          after do |*args| # TODO: sold_at
            params = args.first # expecting keys :buyer, :price
            self.buyer = params[:buyer]
            self.sold_price = params[:price]
          end
        end

        event :not_sold_in_auction do
          transitions from: :bidding_ended, to: :auctioned_unsuccessfully
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

      def bidders
        @bidders ||= bidder_registrations.collect { |br| br.bidder }.sort_by(&:name)
      end

      def current_minimal_bid
        current_price + (current_price == offered_price ? 0 : 1)
      end

      def bid!(bid)
        ActiveRecord::Base.transaction do
          if approved_bid?(bid)
            add_bid(bid)
          else
            bid.errors.add(:bade_at, "too late")
          end

          bid
        end
      end

      private
        def approved_bid?(bid)
          return false if bid.price <= current_price
          return false if winning_bid.present? && (winning_bid.bidder == bid.bidder)
          return false unless in_sale?


          true
        end

        def add_bid(bid)
          self.current_price = bid.price if bid.price > current_price
          save!
          bid.save

          self.winning_bid = bid
        end
    end
  end
end

# == Schema Information
#
# Table name: auctify_sales
#
#  id            :integer          not null, primary key
#  aasm_state    :string           default("offered"), not null
#  buyer_type    :string
#  current_price :decimal(, )
#  item_type     :string           not null
#  offered_price :decimal(, )
#  published_at  :datetime
#  seller_type   :string           not null
#  selling_price :decimal(, )
#  sold_price    :decimal(, )
#  type          :string           default("Auctify::Sale::Base")
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  buyer_id      :integer
#  item_id       :integer          not null
#  seller_id     :integer          not null
#
# Indexes
#
#  index_auctify_sales_on_buyer_type_and_buyer_id    (buyer_type,buyer_id)
#  index_auctify_sales_on_item_type_and_item_id      (item_type,item_id)
#  index_auctify_sales_on_seller_type_and_seller_id  (seller_type,seller_id)
#
