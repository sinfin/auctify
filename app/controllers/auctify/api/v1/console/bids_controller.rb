# frozen_string_literal: true

module Auctify
  module Api
    module V1
      module Console
        class BidsController < Auctify::Api::V1::BaseController # Folio::Console::Api::BaseController
          before_action :api_authenticate_account!
          before_action :find_bid, except: [:index]

          def index
            scope = if params[:auction_id].present?
              @auction = Auctify::Sale::Auction.find(params[:auction_id])
              @auction&.bids
            else
              Auctify::Bid.all
            end
            @bids = scope
          end

          def show
          end

          def destroy
            if @bid.cancel!
              @auction = @bid.auction
              @bids = @auction.bids

              render :index
            else
              render json: @bid.errors
            end
          end

          private
            def find_bid
              @bid = Auctify::Bid.find(params[:id])
            end

            def bidder_registration
              @bidder_registration ||= @bid.bidder_registrations.find_by(bidder: current_user)
            end

            def api_authenticate_account!
              fail CanCan::AccessDenied if current_account.blank?
            end
        end
      end
    end
  end
end
