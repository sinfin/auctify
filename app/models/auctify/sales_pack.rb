# frozen_string_literal: true

module Auctify
  class SalesPack < ApplicationRecord
    include Folio::FriendlyId
    include Folio::HasAttachments
    include Folio::Positionable
    include Folio::Publishable::Basic
    include Folio::Sitemap::Base

    has_many :sales, class_name: "Auctify::Sale::Base", foreign_key: :pack_id, inverse_of: :pack, dependent: :restrict_with_error
    has_many :items, through: :sales

    validates :title,
              presence: true,
              uniqueness: true

    validates :start_date,
              :end_date,
              presence: true

    validates :sales_interval,
              numericality: { greater_than: 0, less_than: 240 }

    validates :sales_beginning_hour,
              numericality: { greater_than_or_equal: 0, less_than: 24 }

    validates :sales_beginning_minutes,
              numericality: { greater_than_or_equal: 0, less_than: 60 }

    validate :validate_start_and_end_dates
    validate :sales_ends_in_pack_time_frame

    scope :ordered, -> { order(start_date: :desc, id: :desc) }

    pg_search_scope :by_query,
                    against: %i[title],
                    ignoring: :accents,
                    using: { tsearch: { prefix: true } }

    after_initialize :set_commission

    def to_label
      title
    end

    def dates_to_label
      return "" unless start_date && end_date

      date_strings = []
      if start_date.year == end_date.year
        if start_date.month == end_date.month
          # all inside same month
          date_strings << start_date.strftime("%-d.")
        else
          # all inside same year
          date_strings << start_date.strftime("%-d. %-m.")
        end
      else
        # crossing years border
        date_strings << start_date.strftime("%-d. %-m. %Y")
      end

      date_strings << end_date.strftime("%-d. %-m. %Y")
      date_strings.join(" – ")
    end

    def shift_sales_by_minutes!(shift_in_minutes)
      self.transaction do
        sales.each do |sale|
          sale.update!(ends_at: sale.ends_at + shift_in_minutes.minutes)

          validate_sale_ends_in_time_frame(sale)
          raise ActiveRecord::RecordInvalid if errors[:sales].present?
        end
      end
      sales.reload
    end

    def time_frame
      (start_date.to_time..(end_date.to_time + 1.day))
    end

    private
      def validate_start_and_end_dates
        if start_date.present? && end_date.present? && start_date > end_date
          errors.add(:end_date, :smaller_than_start_date)
        end
      end

      def sales_ends_in_pack_time_frame
        return if changes["start_date"].present? || changes["end_date"]

        sales.select(:id, :slug, :ends_at).each do |sale|
          validate_sale_ends_in_time_frame(sale)
        end
      end

      def set_commission
        return if self.commission_in_percent.present?

        self.commission_in_percent = Auctify.configuration.auctioneer_commission_in_percent
      end

      def validate_sale_ends_in_time_frame(sale)
        unless time_frame.cover?(sale.ends_at)
          errors.add(:sales,
                    :sale_is_out_of_time_frame,
                    slug: sale.slug.blank? ? "##{sale.id}" : sale.slug,
                    ends_at_time: I18n.l(sale.ends_at))
        end
      end
  end
end

# == Schema Information
#
# Table name: auctify_sales_packs
#
#  id                                  :bigint(8)        not null, primary key
#  title                               :string
#  description                         :text
#  position                            :integer          default(0)
#  slug                                :string
#  place                               :string
#  published                           :boolean          default(FALSE)
#  created_at                          :datetime         not null
#  updated_at                          :datetime         not null
#  sales_count                         :integer          default(0)
#  start_date                          :date
#  end_date                            :date
#  sales_interval                      :integer          default(3)
#  sales_beginning_hour                :integer          default(20)
#  sales_beginning_minutes             :integer          default(0)
#  commission_in_percent               :integer
#  auction_prolonging_limit_in_seconds :integer
#  sales_closed_manually               :boolean          default(FALSE)
#
# Indexes
#
#  index_auctify_sales_packs_on_position   (position)
#  index_auctify_sales_packs_on_published  (published)
#  index_auctify_sales_packs_on_slug       (slug) UNIQUE
#
