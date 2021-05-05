# frozen_string_literal: true

module Auctify
  module Sale
    module AuctionCallbacks
      extend ActiveSupport::Concern

      included do
        KNOWN_CALLBACKS = %i[after_start_sale
                             after_bid_appended
                             after_bid_not_appended
                             before_bidding_is_close_to_end
                             after_close_bidding
                             after_sold_in_auction
                             after_not_sold_in_auction]


        (KNOWN_CALLBACKS - [:after_bid_not_appended]).each do |cb|
          define_method cb do
            # override me, if You want
            callback_runs[cb] += 1
          end
        end

        def after_bid_not_appended(errors)
          # override me, if You want
          callback_runs[:after_bid_not_appended] += 1
        end

        def callback_runs
          @callback_runs ||= KNOWN_CALLBACKS.index_with { |cb|  0 }
        end
      end
    end
  end
end
