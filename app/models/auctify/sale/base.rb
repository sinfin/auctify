# frozen_string_literal: true

module Auctify
  module Sale
    class Base < ApplicationRecord
      include Folio::Positionable
      include Folio::Publishable::Basic

      self.table_name = "auctify_sales"

      attribute :bid_steps_ladder, MinimalBidsLadderType.new

      include Auctify::Behavior::Base

      belongs_to :seller, polymorphic: true, optional: true
      belongs_to :buyer, polymorphic: true, optional: true
      # added on usage of `auctify_as :item` =>     belongs_to :item, class_name: ???
      belongs_to :pack, class_name: "Auctify::SalesPack", inverse_of: :sales, optional: true, counter_cache: :sales_count

      validate :valid_seller
      validate :valid_item
      validate :valid_buyer

      validates :offered_price,
                :current_price,
                :sold_price,
                :reserve_price,
                numericality: { greater_than_or_equal_to: 0 },
                allow_nil: true

      scope :not_sold, -> { where(sold_price: nil) }

      delegate :to_label, to: :item

      # need to cover wrong class of item before assigning
      def item=(item)
        @item = item
        valid_item

        super if errors.blank?
      end

      [:seller, :buyer, :item].each do |behavior|
        define_method("#{behavior}_auctify_id=") do |auctify_id|
          self.send("#{behavior}=", object_from_auctify_id(auctify_id))
        end

        define_method("#{behavior}_auctify_id") do
          self.send("#{behavior}")&.auctify_id
        end
      end

      def publish!
        self.published = true
        save
      end

      private
        def valid_seller
          return true if seller_id.blank?

          db_seller = db_presence_of(seller)

          if db_seller.present?
            errors.add(:seller, :not_auctified) unless db_seller.class.included_modules.include?(Auctify::Behavior::Seller) # rubocop:disable Layout/LineLength
          else
            errors.add(:seller, :required)
          end
        end

        def valid_item
          item = @item || self.item
          errors.delete(:item)

          db_item = db_presence_of(item)
          if db_item.present?
            errors.add(:item, :not_auctified) unless db_item.class.included_modules.include?(Auctify::Behavior::Item)
          else
            # Rails will add "required" on item.nil? automagically (and after this validation) but not for non-persisted item
            # we do not allow creating sale along with item, so this trying to cover that
            errors.add(:item, :required) unless item.blank? || errors.details[:item].include?({ error: :blank })
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

        def configuration
          Auctify.configuration
        end
    end
  end
end

# == Schema Information
#
# Table name: auctify_sales
#
#  id                :bigint(8)        not null, primary key
#  seller_type       :string
#  seller_id         :integer
#  buyer_type        :string
#  buyer_id          :bigint(8)
#  item_id           :bigint(8)        not null
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#  type              :string           default("Auctify::Sale::Base")
#  aasm_state        :string           default("offered"), not null
#  offered_price     :decimal(12, 2)
#  current_price     :decimal(12, 2)
#  sold_price        :decimal(12, 2)
#  bid_steps_ladder  :jsonb
#  reserve_price     :decimal(, )
#  pack_id           :bigint(8)
#  ends_at           :datetime
#  position          :integer
#  number            :string
#  currently_ends_at :datetime
#  published         :boolean          default(FALSE)
#  featured          :boolean          default(FALSE)
#
# Indexes
#
#  index_auctify_sales_on_buyer_type_and_buyer_id    (buyer_type,buyer_id)
#  index_auctify_sales_on_featured                   (featured)
#  index_auctify_sales_on_pack_id                    (pack_id)
#  index_auctify_sales_on_position                   (position)
#  index_auctify_sales_on_published                  (published)
#  index_auctify_sales_on_seller_type_and_seller_id  (seller_type,seller_id)
#
