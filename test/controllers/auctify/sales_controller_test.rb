# frozen_string_literal: true

require "test_helper"

module Auctify
  class SalesControllerTest < ActionDispatch::IntegrationTest
    include Engine.routes.url_helpers

    setup do
      @sale = auctify_sales(:accepted_auction)
    end

    test "should get index with published and not ended sales" do
      get sales_url

      assert_response :success

      displayed_sales = auctify_sales(:adam_innocence, :auction_in_progress, :accepted_auction)
      displayed_sales.each do |sale|
        assert response.body.include?(sale.item.name), "Page should include sale '#{sale.item.name}'"
      end

      (Auctify::Sale::Base.all - displayed_sales).each do |sale|
        assert_not response.body.include?(sale.item.name), "Page should not include sale '#{sale.item.name}'"
      end

      skip "time frame is not yet implemented"
    end

    test "should get index with any sales if param list_all=1 is present" do
      get sales_url, params: { list_all: "1" }

      assert_response :success

      displayed_sales = Auctify::Sale::Base.all
      displayed_sales.each do |sale|
        assert response.body.include?(sale.item.name), "Page should include sale '#{sale.item.name}'"
      end

      skip "time frame is not yet implemented"
    end

    test "should get new" do
      get new_auctify_sale_url
      assert_response :success

      assert_select_with(User.all, :seller)
      assert_select_with(User.all, :buyer)
      assert_select_with(Thing.all, :item)
    end

    test "should create sale" do
      assert_difference("Sale::Base.count") do
        post sales_url,
             params: { sale: { seller_auctify_id: @sale.seller_auctify_id,
                               buyer_auctify_id: @sale.buyer_auctify_id,
                               item_auctify_id: @sale.item_auctify_id } }
      end

      assert_redirected_to auctify_sale_url(Sale::Base.last)
    end

    test "should show sale" do
      get auctify_sale_url(@sale)

      assert_response :success
      assert response.body.include?(@sale.item.name)
      assert response.body.include?(@sale.seller.name)
      assert response.body.include?(@sale.buyer.name) if @sale.buyer.present?
    end

    test "should get edit" do
      get edit_auctify_sale_url(@sale)
      assert_response :success

      assert_select_with(User.all, :seller, @sale.seller)
    end

    test "should update sale" do
      patch auctify_sale_url(@sale),
            params: { sale: { seller_auctify_id: users(:adam).auctify_id,
                              buyer_auctify_id: nil,
                              item_auctify_id: things(:leaf).auctify_id } }

      assert_redirected_to auctify_sale_url(@sale)

      assert_equal users(:adam), @sale.reload.seller
      assert_nil @sale.buyer
      assert_equal things(:leaf), @sale.item
    end

    test "should destroy sale" do
      assert_difference("Sale::Base.count", -1) do
        delete auctify_sale_url(@sale)
      end

      assert_redirected_to sales_url
    end

    def assert_select_with(records, type, selected = nil)
      assert_select "select#sale_#{type}_auctify_id option" do |options|
        opt_values = options.each_with_object({}) { |o, h| h[o["value"]] = { text: o.text, selected: o["selected"] } }
        records.each do |r|
          msg = "select options for #{type} should have record `#{r.name}`[#{r.auctify_id}]"

          assert (option = opt_values[r.auctify_id]).present?, msg + " : options  #{opt_values}"
          assert_equal r.name, option[:text], msg + " but got #{option}"
          if selected.present?
            if r == selected
              assert_equal "selected", option[:selected], msg + " set as selected: #{options}"
            else
              assert_not_equal "selected", option[:selected], msg + " set as NOT selected: #{options}"
            end
          end
        end
      end
    end
  end
end
