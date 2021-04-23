# frozen_string_literal: true

module Auctify
  module Sale
    class Base < ApplicationRecord
      self.table_name = "auctify_sales"

      attribute :bid_steps_ladder, MinimalBidsLadderType.new

      include Auctify::Behavior::Base

      belongs_to :seller, polymorphic: true
      belongs_to :buyer, polymorphic: true, optional: true
      belongs_to :item, polymorphic: true
      belongs_to :pack, class_name: "Auctify::SalesPack", inverse_of: :sales, optional: true

      validate :valid_seller
      validate :valid_item
      validate :valid_buyer

      scope :published, -> { where("published_at <= ?", Time.current) }
      scope :not_sold, -> { where(sold_price: nil) }

      delegate :to_label, to: :item

      [:seller, :buyer, :item].each do |behavior|
        define_method("#{behavior}_auctify_id=") do |auctify_id|
          self.send("#{behavior}=", object_from_auctify_id(auctify_id))
        end

        define_method("#{behavior}_auctify_id") do
          self.send("#{behavior}")&.auctify_id
        end
      end

      def publish!
        publish_from(Time.current)
        save
      end

      def publish_from(time)
        self.published_at = time
      end

      def published?
        published_at && (published_at <= Time.current)
      end

      private
        def valid_seller
          db_seller = db_presence_of(seller)

          if db_seller.present?
            errors.add(:seller, :not_auctified) unless db_seller.class.included_modules.include?(Auctify::Behavior::Seller) # rubocop:disable Layout/LineLength
          else
            errors.add(:seller, :required)
          end
        end

        def valid_item
          db_item = db_presence_of(item)
          if db_item.present?
            errors.add(:item, :not_auctified) unless db_item.class.included_modules.include?(Auctify::Behavior::Item)
          else
            errors.add(:item, :required)
          end
        end

        def valid_buyer
          db_buyer = db_presence_of(buyer)
          if db_buyer.present?
            errors.add(:buyer, :not_auctified) unless db_buyer.class.included_modules.include?(Auctify::Behavior::Buyer)
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
#  id               :bigint(8)        not null, primary key
#  seller_type      :string           not null
#  seller_id        :bigint(8)        not null
#  buyer_type       :string
#  buyer_id         :bigint(8)
#  item_type        :string           not null
#  item_id          :bigint(8)        not null
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#  type             :string           default("Auctify::Sale::Base")
#  aasm_state       :string           default("offered"), not null
#  offered_price    :decimal(12, 2)
#  current_price    :decimal(12, 2)
#  sold_price       :decimal(12, 2)
#  published_at     :datetime
#  bid_steps_ladder :jsonb
#  reserve_price    :decimal(, )
#  pack_id          :bigint(8)
#  ends_at          :datetime
#  position         :integer
#  number           :string
#
# Indexes
#
#  index_auctify_sales_on_buyer_type_and_buyer_id    (buyer_type,buyer_id)
#  index_auctify_sales_on_item_type_and_item_id      (item_type,item_id)
#  index_auctify_sales_on_pack_id                    (pack_id)
#  index_auctify_sales_on_position                   (position)
#  index_auctify_sales_on_published_at               (published_at)
#  index_auctify_sales_on_seller_type_and_seller_id  (seller_type,seller_id)
#
