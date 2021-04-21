# frozen_string_literal: true

class RemoveSellingPriceFromAuctifySales < ActiveRecord::Migration[6.0]
  def change
    remove_column :auctify_sales, :selling_price, :decimal
  end
end
