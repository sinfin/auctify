# frozen_string_literal: true

module Auctify
  module Api
    module V1
      module Console
        class BidsController < Auctify::Api::V1::BaseController # Folio::Console::Api::BaseController
          before_action :api_authenticate_account!
          before_action :find_bid, except: [:index]

          def destroy
            auction = @bid.auction

            if @bid.cancel!
              render_list(auction.reload)
            else
              render_invalid(@bid)
            end
          end

          private
            def find_bid
              @bid = Auctify::Bid.find(params[:id])
            end

            def api_authenticate_account!
              fail CanCan::AccessDenied if current_account.blank?
            end

            def render_list(auction)
              render json: { data: cell("folio/console/auctify/auctions/bid_list", auction).show }
            end
        end
      end
    end
  end
end
