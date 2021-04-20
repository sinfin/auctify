# frozen_string_literal: true

require_dependency "auctify/application_controller"

module Auctify
  class SalesController < ApplicationController
    before_action :set_sale, only: [:show, :edit, :update, :destroy]

    # GET /sales
    def index
      @sales = scoped_sales.all
    end

    # GET /sales/1
    def show
    end

    # GET /sales/new
    def new
      @sale = sale_class.new
    end

    # GET /sales/1/edit
    def edit
    end

    # POST /sales
    def create
      @sale = sale_class.new(sale_params)

      if @sale.save
        redirect_to auctify_sale_path(@sale), notice: "Sale was successfully created."
      else
        render :new
      end
    end

    # PATCH/PUT /sales/1
    def update
      if @sale.update(sale_params)
        redirect_to auctify_sale_path(@sale), notice: "Sale was successfully updated."
      else
        render :edit
      end
    end

    # DELETE /sales/1
    def destroy
      @sale.destroy
      redirect_to auctify_sales_url, notice: "Sale was successfully destroyed."
    end

    private
      def sale_class
        Sale::Base
      end

      # Use callbacks to share common setup or constraints between actions.
      def set_sale
        @sale = scoped_sales.find(params[:id])
      end

      # Only allow a trusted parameter "white list" through.
      def sale_params
        params.require(:sale).permit(:seller_auctify_id, :buyer_auctify_id, :item_auctify_id, :published)
      end

      def scoped_sales
        scope = sale_class
        return scope if params[:list_all].to_s == "1"

        scope.published.not_sold
      end
  end
end
