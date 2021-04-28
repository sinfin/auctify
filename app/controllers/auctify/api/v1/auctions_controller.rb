# frozen_string_literal: true

module Auctify
  module Api
    module V1
      class AuctionsController < Auctify::Api::V1::BaseController
        before_action :find_auction, except: [:index]

        def show
          render_record @auction
        end

        def bids
          if @auction.bid!(new_bid)
            render_record @auction.reload
          else
            render_invalid new_bid # new_bid.errors
          end
        end

        private
          def find_auction
            @auction = Auctify::Sale::Auction.find(params[:id])
          end

          def bid_params
            params.require(:bid).permit(:max_price, :price)
          end

          def new_bid
            @new_bid ||= Auctify::Bid.new(bid_params.merge(registration: bidder_registration))
          end

          def bidder_registration
            @bidder_registration ||= @auction.bidder_registrations.find_by(bidder: current_user)
          end
      end
    end
  end
end
