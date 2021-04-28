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
      state :approved, color: "green"
      state :rejected, color: "black"

      event :approve do
        transitions from: :pending, to: :approved

        before do
          self.handled_at = Time.current
        end
      end

      event :unapprove do
        transitions from: :approved, to: :pending

        before do
          self.handled_at = nil
        end
      end

      event :reject do
        transitions from: :pending, to: :rejected

        before do
          self.handled_at = Time.current
        end
      end
    end

    validate :auction_is_in_allowed_state, on: :create

    private
      def auction_is_in_allowed_state
        unless auction && auction.allows_new_bidder_registrations?
          errors.add(:auction, :auction_do_not_allow_new_registrations)
        end
      end
  end
end

# == Schema Information
#
# Table name: auctify_bidder_registrations
#
#  id          :bigint(8)        not null, primary key
#  bidder_type :string           not null
#  bidder_id   :bigint(8)        not null
#  auction_id  :bigint(8)        not null
#  aasm_state  :string           default("pending"), not null
#  handled_at  :datetime
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#
# Indexes
#
#  index_auctify_bidder_registrations_on_aasm_state  (aasm_state)
#  index_auctify_bidder_registrations_on_auction_id  (auction_id)
#  index_auctify_bidder_registrations_on_bidder      (bidder_type,bidder_id)
#
# Foreign Keys
#
#  fk_rails_...  (auction_id => auctify_sales.id)
#
