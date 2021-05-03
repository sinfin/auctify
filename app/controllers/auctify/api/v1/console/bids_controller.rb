# frozen_string_literal: true

module Auctify
  module Api
    module V1
      module Console
        class BidsController < Folio::Console::Api::BaseController
          before_action :find_bid, except: [:index]

          def destroy
            if @bid.cancel!
            else
              #render errors
            end
            # render some response
          end


          private
            def find_bid
              @bid = Auctify::Bid.find(params[:id])
            end

            def bidder_registration
              @bidder_registration ||= @bid.bidder_registrations.find_by(bidder: current_user)
            end
        end
      end
    end
  end
end
