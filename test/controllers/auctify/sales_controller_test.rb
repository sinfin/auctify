# frozen_string_literal: true

require "test_helper"

module Auctify
  class SalesControllerTest < ActionDispatch::IntegrationTest
    include Engine.routes.url_helpers

    setup do
      @sale = auctify_sales(:eve_apple)
    end

    test "should get index" do
      get sales_url
      assert_response :success
    end

    test "should get new" do
      get new_sale_url
      assert_response :success
    end

    test "should create sale" do
      assert_difference("Sale::Base.count") do
        post sales_url,
params: { sale: { buyer_id: @sale.buyer_id, buyer_type: @sale.buyer_type, item_id: @sale.item_id,
item_type: @sale.item_type, seller_id: @sale.seller_id, seller_type: @sale.seller_type } }
      end

      assert_redirected_to sale_url(Sale::Base.last)
    end

    test "should show sale" do
      get sale_url(@sale)
      assert_response :success
    end

    test "should get edit" do
      get edit_sale_url(@sale)
      assert_response :success
    end

    test "should update sale" do
      patch sale_url(@sale),
params: { sale: { buyer_id: @sale.buyer_id, buyer_type: @sale.buyer_type, item_id: @sale.item_id,
item_type: @sale.item_type, seller_id: @sale.seller_id, seller_type: @sale.seller_type } }
      assert_redirected_to sale_url(@sale)
    end

    test "should destroy sale" do
      assert_difference("Sale::Base.count", -1) do
        delete sale_url(@sale)
      end

      assert_redirected_to sales_url
    end
  end
end
