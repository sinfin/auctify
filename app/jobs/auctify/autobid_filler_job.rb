# frozen_string_literal: true

module Auctify
  class AutobidFillerJob < Auctify::ApplicationJob
    queue_as :default

    def perform
      reg_ids = Auctify::Bid.pluck(:registration_id).uniq
      registrations_with_bids = Auctfy::BidderRegistration.where(id: reg_ids)

      registrations_with_bids.find_each { |reg| reg.fillup_autobid_flags! }
    end
  end
end
