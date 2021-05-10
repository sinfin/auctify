# frozen_string_literal: true

module Auctify
  module Sale
    module AuctionCallbacks
      extend ActiveSupport::Concern

      included do
        CALLBACKS_WITHOUT_ARGS = %i[after_start_sale
                                    before_bidding_is_close_to_end
                                    after_close_bidding
                                    after_sold_in_auction
                                    after_not_sold_in_auction]
        CALLBACKS_WITH_ARGS = %i[after_bid_appended
                                 after_bid_not_appended ]


        CALLBACKS_WITHOUT_ARGS.each do |cb|
          define_method cb do
            # override me, if You want
            callback_runs[cb] += 1
          end
        end

        def after_bid_appended(bid_appender)
          # override me, if You want
          # see bid_appender.result
          # to get previous_winning bid, call `previous_winning_bid(bid_appender.bid)`
          callback_runs[:after_bid_appended] += 1
        end

        def after_bid_not_appended(bid_appender)
          # override me, if You want
          # see bid_appender.errors
          callback_runs[:after_bid_not_appended] += 1
        end

        def callback_runs
          @callback_runs ||= (CALLBACKS_WITH_ARGS + CALLBACKS_WITHOUT_ARGS).index_with { |cb|  0 }
        end
      end
    end
  end
end
