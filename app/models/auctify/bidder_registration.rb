# frozen_string_literal: true

module Auctify
  class BidderRegistration < ApplicationRecord
    include AASM

    belongs_to :bidder, polymorphic: true
    belongs_to :auction, class_name: "Auctify::Sale::Auction", inverse_of: :bidder_registrations
    has_many :bids, class_name: "Auctify::Bid",
                    foreign_key: "registration_id",
                    inverse_of: :registration,
                    dependent: :destroy

    aasm do
      state :pending, initial: true, color: "gray"
      state :handled, color: "green"

      event :handle do
        before do
          self.handled_at = Time.current
        end
        transitions from: :pending, to: :handled
      end

      event :unhandle do
        transitions from: :handled, to: :pending
      end
    end
  end
end

# == Schema Information
#
# Table name: auctify_bidder_registrations
#
#  id          :integer          not null, primary key
#  aasm_state  :string           default("pending"), not null
#  bidder_type :string           not null
#  handled_at  :datetime
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  auction_id  :integer          not null
#  bidder_id   :integer          not null
#
# Indexes
#
#  index_auctify_bidder_registrations_on_aasm_state  (aasm_state)
#  index_auctify_bidder_registrations_on_auction_id  (auction_id)
#  index_auctify_bidder_registrations_on_bidder      (bidder_type,bidder_id)
#
# Foreign Keys
#
#  auction_id  (auction_id => auctify_sales.id)
#
