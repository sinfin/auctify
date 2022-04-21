# frozen_string_literal: true

module Auctify
  class ApplicationJob < ActiveJob::Base
    private
      def auction_label(auction)
        "[#{auction.try(:slug)}##{auction.id}; currently_ends_at: #{auction.currently_ends_at}]"
      end
  end
end
