# frozen_string_literal: true

module Auctify
  class Bid < ApplicationRecord
    belongs_to :registration, class_name: "Auctify::BidderRegistration", inverse_of: :bids

    delegate :bidder, :auction, to: :registration

    def bade_at
      created_at
    end
  end
end

# == Schema Information
#
# Table name: auctify_bids
#
#  id              :integer          not null, primary key
#  max_price       :decimal(12, 2)
#  price           :decimal(12, 2)   not null
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  registration_id :integer          not null
#
# Indexes
#
#  index_auctify_bids_on_registration_id  (registration_id)
#
# Foreign Keys
#
#  registration_id  (registration_id => auctify_bidder_registrations.id)
#
