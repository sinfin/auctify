# frozen_string_literal: true

module Auctify
  module Behavior
    module Buyer
      extend ActiveSupport::Concern

      include Auctify::Behavior::Base

      included do
        has_many :purchases, as: :buyer, class_name: "Auctify::Sale::Base"
        has_many :bidder_registrations, as: :bidder, class_name: "Auctify::BidderRegistration"
      end
    end
  end
end
