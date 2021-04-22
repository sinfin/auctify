# frozen_string_literal: true

require "test_helper"

module Auctify
  class SalesPacksControllerTest < ActionDispatch::IntegrationTest
    include Engine.routes.url_helpers

    setup do
      @sales_pack = auctify_sales_packs(:published_pack)
    end

    test "should get index" do
      get auctify_sales_packs_url
      assert_response :success
    end

    test "should get new" do
      get new_auctify_sales_pack_url
      assert_response :success
    end

    test "should create sales_pack" do
      assert_difference("Auctify::SalesPack.count") do
        post auctify_sales_packs_url, params: { sales_pack: { description: @sales_pack.description,
                                                      place: @sales_pack.place,
                                                      position: @sales_pack.position,
                                                      published: @sales_pack.published,
                                                      slug: @sales_pack.slug,
                                                      time_frame: @sales_pack.time_frame,
                                                      title: @sales_pack.title + "New" } }
      end

      assert_redirected_to auctify_sales_pack_url(SalesPack.last)
    end

    test "should show sales_pack" do
      get auctify_sales_pack_url(@sales_pack)
      assert_response :success
    end

    test "should get edit" do
      get edit_auctify_sales_pack_url(@sales_pack)
      assert_response :success
    end

    test "should update sales_pack" do
      patch auctify_sales_pack_url(@sales_pack), params: { sales_pack: { description: @sales_pack.description,
                                                                 place: @sales_pack.place,
                                                                 position: @sales_pack.position,
                                                                 published: @sales_pack.published,
                                                                 slug: @sales_pack.slug,
                                                                 time_frame: @sales_pack.time_frame,
                                                                 title: @sales_pack.title } }
      assert_redirected_to auctify_sales_pack_url(@sales_pack)
    end

    test "should destroy sales_pack" do
      assert_difference("Auctify::SalesPack.count", -1) do
        delete auctify_sales_pack_url(@sales_pack)
      end

      assert_redirected_to auctify_sales_packs_url
    end
  end
end
