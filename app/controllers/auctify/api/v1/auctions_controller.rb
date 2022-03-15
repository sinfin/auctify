# frozen_string_literal: true

module Auctify
  module Api
    module V1
      class AuctionsController < Auctify::Api::V1::BaseController
        before_action :find_auction, except: [:index]

        def show
          if params[:updated_at].present? && params[:updated_at].match?(/\A\d+\z/) && params[:updated_at].to_i == @auction.updated_at.to_i
            render json: { current: true }, status: 200
          else
            render_record @auction
          end
        end

        def bids
          if params[:confirmation] == "1"
            if @auction.bid!(new_bid)
              @auction.reload

              store_dont_confirm_bids

              render_record @auction, success: true, overbid_by_limit: overbid_by_limit?(new_bid)
            else
              store_dont_confirm_bids

              render_record @auction, bid: new_bid, status: 400
            end
          else
            new_bid.errors.add(:base, :not_confirmed)
            render_record @auction, bid: new_bid, status: 400
          end
        end

        def close_manually
          if @auction.close_manually(by: current_account, price_check: params[:current_price])
            render_record @auction
          else
            render_record @auction, status: 400
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
            @new_bid ||= Auctify::Bid.new(bid_params.merge(registration_params))
          end

          def registration_params
            bidder_registration = @auction.bidder_registrations.find_by(bidder: current_user)
            return  { registration: bidder_registration } if bidder_registration.present?

            { bidder: current_user }
          end

          def render_record(auction, bid: nil, status: 200, success: nil, overbid_by_limit: nil)
            render json: {
              data: cell("#{global_namespace_path}/auctify/auctions/form",
                         auction,
                         bid: bid,
                         success: success,
                         overbid_by_limit: overbid_by_limit).show
            }, status: status
          end

          def store_dont_confirm_bids
            if params[:dont_confirm_bids] == "1"
              # use SQL update in case of some obscure invalid attributes
              bidder_regs = current_user.bidder_registrations.where(auction: @auction)
              bidder_regs.update_all(dont_confirm_bids: true) if bidder_regs.present?
            end
          end

          def overbid_by_limit?(new_bid)
            winning_bid = @auction&.winning_bid
            return false unless winning_bid
            return false if new_bid.id.blank? || winning_bid.id.blank?
            return false if winning_bid.registration_id == new_bid.registration_id # do not notify bidder about overbidding itself

            winning_bid != new_bid
          end
      end
    end
  end
end
