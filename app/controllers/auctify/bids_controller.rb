# frozen_string_literal: true

require_dependency "auctify/application_controller"

module Auctify
  class BidsController < ApplicationController
    before_action :set_bid, only: [:show, :edit, :update, :destroy]

    # GET /bids
    def index
      @bids = Bid.all
    end

    # GET /bids/1
    def show
    end

    # GET /bids/new
    def new
      @bid = Bid.new
    end

    # GET /bids/1/edit
    def edit
    end

    # POST /bids
    def create
      @bid = Bid.new(bid_params)

      if @bid.save
        redirect_to @bid, notice: "Bid was successfully created."
      else
        render :new
      end
    end

    # PATCH/PUT /bids/1
    def update
      if @bid.update(bid_params)
        redirect_to @bid, notice: "Bid was successfully updated."
      else
        render :edit
      end
    end

    # DELETE /bids/1
    def destroy
      @bid.destroy
      redirect_to bids_url, notice: "Bid was successfully destroyed."
    end

    private
      # Use callbacks to share common setup or constraints between actions.
      def set_bid
        @bid = Bid.find(params[:id])
      end

      # Only allow a trusted parameter "white list" through.
      def bid_params
        params.require(:bid).permit(:registration_id, :price, :max_price)
      end
  end
end
