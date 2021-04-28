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
        end

        private
          def find_auction
            @auction = Auctify::Sale::Auction.find(params[:id])
          end
      end
    end
  end
end
