# frozen_string_literal: true

class AddPricesToAuctifySales < ActiveRecord::Migration[6.0]
  def change
    add_column :auctify_sales, :offered_price, :decimal, precision: 12, scale: 2
    add_column :auctify_sales, :current_price, :decimal, precision: 12, scale: 2
    add_column :auctify_sales, :sold_price, :decimal, precision: 12, scale: 2
  end
end
