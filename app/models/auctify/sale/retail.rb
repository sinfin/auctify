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
#  id            :integer          not null, primary key
#  aasm_state    :string           default("offered"), not null
#  buyer_type    :string
#  item_type     :string           not null
#  offered_price :decimal(, )
#  published_at  :datetime         default(NULL)
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
