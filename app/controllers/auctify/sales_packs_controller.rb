# frozen_string_literal: true

require_dependency "auctify/application_controller"

module Auctify
  class SalesPacksController < ApplicationController
    before_action :set_sales_pack, only: [:show, :edit, :update, :destroy]

    # GET /sales_packs
    def index
      @sales_packs = SalesPack.all
    end

    # GET /sales_packs/1
    def show
    end

    # GET /sales_packs/new
    def new
      @sales_pack = SalesPack.new
    end

    # GET /sales_packs/1/edit
    def edit
    end

    # POST /sales_packs
    def create
      @sales_pack = SalesPack.new(sales_pack_params)

      if @sales_pack.save
        redirect_to @sales_pack, notice: "Sales pack was successfully created."
      else
        render :new
      end
    end

    # PATCH/PUT /sales_packs/1
    def update
      if @sales_pack.update(sales_pack_params)
        redirect_to @sales_pack, notice: "Sales pack was successfully updated."
      else
        render :edit
      end
    end

    # DELETE /sales_packs/1
    def destroy
      @sales_pack.destroy
      redirect_to sales_packs_url, notice: "Sales pack was successfully destroyed."
    end

    private
      # Use callbacks to share common setup or constraints between actions.
      def set_sales_pack
        @sales_pack = SalesPack.find(params[:id])
      end

      # Only allow a trusted parameter "white list" through.
      def sales_pack_params
        params.require(:sales_pack).permit(:title, :description, :position, :slug, :time_frame, :place, :published)
      end
  end
end
