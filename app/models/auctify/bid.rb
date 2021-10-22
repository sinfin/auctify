# frozen_string_literal: true

module Auctify
  class Bid < ApplicationRecord
    belongs_to :registration, class_name: "Auctify::BidderRegistration", inverse_of: :bids

    scope :ordered, -> { order(price: :desc, id: :desc) }
    scope :applied, -> { where(cancelled: false) }
    scope :canceled, -> { where(cancelled: true) }
    scope :with_limit, -> { where.not(max_price: nil) }

    validate :price_is_not_bigger_then_max_price
    validate :price_is_rounded

    def <=>(other)
      r = (self.price <=> other.price)
      r = (self.created_at <=> other.created_at) if r.zero?
      r = (self.id <=> other.id) if r.zero?
      r
    end

    def cancel!
      update!(cancelled: true)

      auction.recalculate_bidding!
    end

    def with_limit?
      limit.present?
    end

    def limit
      max_price
    end

    def bade_at
      created_at
    end

    def price_is_not_bigger_then_max_price
      errors.add(:price, :must_be_lower_or_equal_max_price) if max_price && max_price < price
    end

    def price_is_rounded
      round_to = configuration.require_bids_to_be_rounded_to
      errors.add(:price, :must_be_rounded_to, { round_to: round_to }) if price && (price != round_it_to(price, round_to))
      errors.add(:max_price, :must_be_rounded_to, { round_to: round_to }) if max_price && (max_price != round_it_to(max_price, round_to))
    end

    def bidder=(auctified_model)
      errors.add(:bidder, :not_auctified) unless auctified_model.class.included_modules.include?(Auctify::Behavior::Buyer)
      raise "There is already registration for this bid!"  if registration.present?
      @bidder = auctified_model
    end

    def bidder
      @bidder ||= registration&.bidder
    end

    def auction
      registration&.auction
    end

    def configuration
      Auctify.configuration
    end

    private
      def round_it_to(amount, smallest_amount)
        smallest_amount = smallest_amount.to_i
        (smallest_amount * ((amount + (smallest_amount / 2)).to_i / smallest_amount))
      end
  end
end

# == Schema Information
#
# Table name: auctify_bids
#
#  id              :bigint(8)        not null, primary key
#  registration_id :integer          not null
#  price           :decimal(12, 2)   not null
#  max_price       :decimal(12, 2)
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  cancelled       :boolean          default(FALSE)
#  autobid         :boolean          default(FALSE)
#
# Indexes
#
#  index_auctify_bids_on_cancelled        (cancelled)
#  index_auctify_bids_on_registration_id  (registration_id)
#
# Foreign Keys
#
#  fk_rails_...  (registration_id => auctify_bidder_registrations.id)
#
