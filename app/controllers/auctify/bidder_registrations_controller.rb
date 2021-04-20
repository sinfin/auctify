# frozen_string_literal: true

require_dependency "auctify/application_controller"

module Auctify
  class BidderRegistrationsController < ApplicationController
    before_action :set_bidder_registration, only: [:show, :edit, :update, :destroy]

    # GET /bidder_registrations
    def index
      @bidder_registrations = BidderRegistration.all
    end

    # GET /bidder_registrations/1
    def show
    end

    # GET /bidder_registrations/new
    def new
      @bidder_registration = BidderRegistration.new
    end

    # GET /bidder_registrations/1/edit
    def edit
    end

    # POST /bidder_registrations
    def create
      @bidder_registration = BidderRegistration.new(bidder_registration_params)

      if @bidder_registration.save
        redirect_to @bidder_registration, notice: "Bidder registration was successfully created."
      else
        render :new
      end
    end

    # PATCH/PUT /bidder_registrations/1
    def update
      if @bidder_registration.update(bidder_registration_params)
        redirect_to @bidder_registration, notice: "Bidder registration was successfully updated."
      else
        render :edit
      end
    end

    # DELETE /bidder_registrations/1
    def destroy
      @bidder_registration.destroy
      redirect_to auctify_bidder_registrations_url, notice: "Bidder registration was successfully destroyed."
    end

    private
      # Use callbacks to share common setup or constraints between actions.
      def set_bidder_registration
        @bidder_registration = BidderRegistration.find(params[:id])
      end

      # Only allow a trusted parameter "white list" through.
      def bidder_registration_params
        params.require(:bidder_registration).permit(:bidder_id, :bidder_type, :auction_id, :aasm_state, :submitted_at,
:handled_at)
      end
  end
end
