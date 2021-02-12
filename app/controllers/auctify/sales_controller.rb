# frozen_string_literal: true

require_dependency "auctify/application_controller"

module Auctify
  class SalesController < ApplicationController
    before_action :set_sale, only: [:show, :edit, :update, :destroy]

    # GET /sales
    def index
      @sales = Sale.all
    end

    # GET /sales/1
    def show
    end

    # GET /sales/new
    def new
      @sale = Sale.new
    end

    # GET /sales/1/edit
    def edit
    end

    # POST /sales
    def create
      @sale = Sale.new(sale_params)

      if @sale.save
        redirect_to @sale, notice: "Sale was successfully created."
      else
        render :new
      end
    end

    # PATCH/PUT /sales/1
    def update
      if @sale.update(sale_params)
        redirect_to @sale, notice: "Sale was successfully updated."
      else
        render :edit
      end
    end

    # DELETE /sales/1
    def destroy
      @sale.destroy
      redirect_to sales_url, notice: "Sale was successfully destroyed."
    end

    private
      # Use callbacks to share common setup or constraints between actions.
      def set_sale
        @sale = Sale.find(params[:id])
      end

      # Only allow a trusted parameter "white list" through.
      def sale_params
        params.require(:sale).permit(:seller_id, :seller_type, :buyer_id, :buyer_type, :item_id, :item_type)
      end
  end
end
