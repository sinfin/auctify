# frozen_string_literal: true

require "test_helper"

module Auctify
  module Sale
    class AuctionSetupTest < ActiveSupport::TestCase
      attr_reader :auction

      test "have initial auctioneer_commission from config" do
        auction = Auctify::Sale::Auction.new
        assert_equal Auctify.configuration.auctioneer_commission_in_percent, auction.commission_in_percent
        assert auction.auctioneer_commission_in_percent.present?
      end
    end
  end
end
