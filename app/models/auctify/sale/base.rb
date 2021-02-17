# frozen_string_literal: true

module Auctify
  module Sale
    class Base < ApplicationRecord
      self.table_name = "auctify_sales"

      include AASM

      belongs_to :seller, polymorphic: true
      belongs_to :buyer, polymorphic: true, optional: true
      belongs_to :item, polymorphic: true

      validate :valid_seller
      validate :valid_item
      validate :valid_buyer

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
            # self.sold_price = params[:price]
          end
        end

        event :end_sale do
          transitions from: :in_sale, to: :not_sold
        end

        event :cancel do
          transitions from: [:offered, :accepted], to: :cancelled
        end
      end


      private
        def valid_seller
          db_seller = db_presence_of(seller)

          if db_seller.present?
            errors.add(:seller, :not_auctified) unless db_seller.class.included_modules.include?(Auctify::Seller)
          else
            errors.add(:seller, :required)
          end
        end

        def valid_item
          db_item = db_presence_of(item)
          if db_item.present?
            errors.add(:item, :not_auctified) unless db_item.class.included_modules.include?(Auctify::Item)
          else
            errors.add(:item, :required)
          end
        end

        def valid_buyer
          db_buyer = db_presence_of(buyer)
          if db_buyer.present?
            errors.add(:buyer, :not_auctified) unless db_buyer.class.included_modules.include?(Auctify::Buyer)
          elsif buyer.present?
            errors.add(:buyer, :required)
          end
        end

        def db_presence_of(record)
          return nil if record.blank?

          record.reload
        rescue ActiveRecord::RecordNotFound
          nil
        end
    end
  end
end

# == Schema Information
#
# Table name: auctify_sales
#
#  id          :integer          not null, primary key
#  aasm_state  :string           default("offered"), not null
#  buyer_type  :string
#  item_type   :string           not null
#  seller_type :string           not null
#  type        :string           default("Auctify::Sale::Base")
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  buyer_id    :integer
#  item_id     :integer          not null
#  seller_id   :integer          not null
#
# Indexes
#
#  index_auctify_sales_on_buyer_type_and_buyer_id    (buyer_type,buyer_id)
#  index_auctify_sales_on_item_type_and_item_id      (item_type,item_id)
#  index_auctify_sales_on_seller_type_and_seller_id  (seller_type,seller_id)
#
