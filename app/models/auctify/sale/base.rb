# frozen_string_literal: true

module Auctify
  module Sale
    class Base < ApplicationRecord
      include Folio::FriendlyId
      include Folio::Featurable::WithPosition
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

      validate :validate_offered_price_when_published

      scope :not_sold, -> { where(sold_price: nil) }
      scope :ordered, -> { order(currently_ends_at: :asc, id: :asc) }

      # need auction scopes here because of has_many :sales, class_name: "Auctify::Sale::Base"
      scope :auctions_open_for_bids, -> do
        where(aasm_state: "in_sale").where("currently_ends_at > ?", Time.current)
      end

      scope :auctions_finished, -> do
        where.not(aasm_state: %w[offered accepted refused]).where("currently_ends_at < ?", Time.current)
      end

      scope :latest_published_by_item, -> { joins(latest_published_sales_by_item_subtable.join_sources) }

      delegate :to_label,
               to: :item

      def self.latest_published_sales_by_item_subtable
        # see https://www.salsify.com/blog/engineering/most-recent-by-group-in-rails
        sales_table = self.arel_table

        latest_sales_query = sales_table.project(sales_table[:item_id],
                                                 sales_table[:id].maximum.as("latest_sale_id"))
                                        .where(sales_table[:published].eq(true))
                                        .group(sales_table[:item_id])

        latest_sales_table = Arel::Table.new(latest_sales_query).alias(:latest_sales)  # need to perform join

        sales_table.join(latest_sales_query.as(latest_sales_table.name.to_s), Arel::Nodes::InnerJoin)
                   .on(sales_table[:id].eq(latest_sales_table[:latest_sale_id]))
      end

      def initialize(*args)
        super

        self.bid_steps_ladder = configuration.default_bid_steps_ladder if bid_steps_ladder.blank?
      end

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

      def auctioneer_commision_from_seller
        (seller_commission_in_percent || 0) * 0.01 * offered_price
      end

      def auctioneer_commision_from_buyer
        return nil if sold_price.nil?

        percent = buyer_commission_in_percent \
                  || (pack&.commission_in_percent) \
                  || Auctify.configuration.auctioneer_commission_in_percent

        sold_price * percent * 0.01
      end

      private
        def valid_seller
          return true if seller_id.blank?

          db_seller = db_presence_of(seller)

          errors.add(:seller, :required) unless db_seller.present?
        end

        def valid_item
          item = @item || self.item
          errors.delete(:item)

          db_item = db_presence_of(item)
          if db_item.present?
            errors.add(:item, :already_on_sale_in_sales_pack, sale_pack_title: pack.title) if pack && pack.sales
                                                                                                          .where(item: db_item)
                                                                                                          .where.not(id: self.id)
                                                                                                          .exists?
          else
            # Rails will add "required" on item.nil? automagically (and after this validation) but not for non-persisted item
            # we do not allow creating sale along with item, so this trying to cover that
            errors.add(:item, :required) unless item.blank? || errors.details[:item].include?({ error: :blank })
          end
        end

        def valid_buyer
          db_buyer = db_presence_of(buyer)
          errors.add(:buyer, :required) if buyer.present? && db_buyer.blank?
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

        def validate_offered_price_when_published
          if published? && offered_price.blank?
            errors.add(:offered_price, :required_for_published)
          end
        end

        def slug_candidates
          base = try(:item).try(:title).presence || self.class.model_name.human
          year = Time.zone.now.year
          [base, "#{base}-#{year}"] + 9.times.map { |i| "#{base}-#{year}-#{i + 2}" }
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
#  buyer_id                     :integer
#  item_id                      :integer          not null
#  created_at                   :datetime         not null
#  updated_at                   :datetime         not null
#  type                         :string           default("Auctify::Sale::Base")
#  aasm_state                   :string           default("offered"), not null
#  offered_price                :decimal(, )
#  current_price                :decimal(, )
#  sold_price                   :decimal(, )
#  bid_steps_ladder             :json
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
#
# Indexes
#
#  index_auctify_sales_on_buyer_type_and_buyer_id    (buyer_type,buyer_id)
#  index_auctify_sales_on_currently_ends_at          (currently_ends_at)
#  index_auctify_sales_on_featured                   (featured)
#  index_auctify_sales_on_pack_id                    (pack_id)
#  index_auctify_sales_on_position                   (position)
#  index_auctify_sales_on_published                  (published)
#  index_auctify_sales_on_seller_type_and_seller_id  (seller_type,seller_id)
#  index_auctify_sales_on_slug                       (slug) UNIQUE
#  index_auctify_sales_on_winner_type_and_winner_id  (winner_type,winner_id)
#
