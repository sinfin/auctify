# frozen_string_literal: true

module Auctify
  module Sale
    class Retail < Auctify::Sale::Base
      include AASM

      aasm do
        state :offered, initial: true, color: "red"
        state :accepted, color: "red"
        state :refused, color: "dark"
        state :in_sale, color: "yellow"
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
            self.currently_ends_at = self.ends_at
            self.buyer = nil
          end

          transitions from: :accepted, to: :in_sale
        end

        event :sell do
          transitions from: :in_sale, to: :sold
          after do |*args| # TODO: sold_at
            params = args.first # expecting keys :buyer, :price
            self.buyer = params[:buyer]
            self.sold_price = params[:price]
          end
        end

        event :end_sale do
          transitions from: :in_sale, to: :not_sold
        end

        event :cancel do
          transitions from: [:offered, :accepted], to: :cancelled
        end
      end
    end
  end
end

# == Schema Information
#
# Table name: auctify_sales
#
#  id                           :bigint(8)        not null, primary key
#  seller_type                  :string
#  seller_id                    :integer
#  buyer_type                   :string
#  buyer_id                     :bigint(8)
#  item_id                      :bigint(8)        not null
#  created_at                   :datetime         not null
#  updated_at                   :datetime         not null
#  type                         :string           default("Auctify::Sale::Base")
#  aasm_state                   :string           default("offered"), not null
#  offered_price                :decimal(12, 2)
#  current_price                :decimal(12, 2)
#  sold_price                   :decimal(12, 2)
#  bid_steps_ladder             :jsonb
#  reserve_price                :decimal(, )
#  pack_id                      :bigint(8)
#  ends_at                      :datetime
#  position                     :integer
#  number                       :string
#  currently_ends_at            :datetime
#  published                    :boolean          default(FALSE)
#  slug                         :string
#  contract_number              :string
#  seller_commission_in_percent :integer
#  winner_type                  :string
#  winner_id                    :bigint(8)
#  applied_bids_count           :integer          default(0)
#  sold_at                      :datetime
#  current_winner_type          :string
#  current_winner_id            :bigint(8)
#  buyer_commission_in_percent  :integer
#  featured                     :integer
#  manually_closed_at           :datetime
#  manually_closed_by_type      :string
#  manually_closed_by_id        :bigint(8)
#  must_be_closed_manually      :boolean          default(FALSE)
#  bidding_locked_at            :datetime
#  bidding_locked_by_type       :string
#  bidding_locked_by_id         :bigint(8)
#
# Indexes
#
#  index_auctify_sales_on_aasm_state                 (aasm_state)
#  index_auctify_sales_on_bidding_locked_by          (bidding_locked_by_type,bidding_locked_by_id)
#  index_auctify_sales_on_buyer_type_and_buyer_id    (buyer_type,buyer_id)
#  index_auctify_sales_on_currently_ends_at          (currently_ends_at)
#  index_auctify_sales_on_featured                   (featured)
#  index_auctify_sales_on_manually_closed_by         (manually_closed_by_type,manually_closed_by_id)
#  index_auctify_sales_on_must_be_closed_manually    (must_be_closed_manually)
#  index_auctify_sales_on_pack_id                    (pack_id)
#  index_auctify_sales_on_position                   (position)
#  index_auctify_sales_on_published                  (published)
#  index_auctify_sales_on_seller_type_and_seller_id  (seller_type,seller_id)
#  index_auctify_sales_on_slug                       (slug) UNIQUE
#  index_auctify_sales_on_winner_type_and_winner_id  (winner_type,winner_id)
#
