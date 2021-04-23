# frozen_string_literal: true

module Auctify
  class Bid < ApplicationRecord
    belongs_to :registration, class_name: "Auctify::BidderRegistration", inverse_of: :bids

    delegate :bidder, :auction, to: :registration

    scope :ordered, -> { order(price: :desc, created_at: :asc, id: :asc) }

    validate :price_is_not_bigger_then_max_price

    def with_limit?
      max_price.present?
    end

    def bade_at
      created_at
    end

    def price_is_not_bigger_then_max_price
      errors.add(:price, :must_be_lower_or_equal_max_price) if max_price && max_price < price
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
#
# Indexes
#
#  index_auctify_bids_on_registration_id  (registration_id)
#
# Foreign Keys
#
#  fk_rails_...  (registration_id => auctify_bidder_registrations.id)
#
