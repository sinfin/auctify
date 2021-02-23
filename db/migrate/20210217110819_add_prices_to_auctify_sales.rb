# frozen_string_literal: true

class AddPricesToAuctifySales < ActiveRecord::Migration[6.0]
  def change
    add_column :auctify_sales, :offered_price, :decimal
    add_column :auctify_sales, :current_price, :decimal
    add_column :auctify_sales, :sold_price, :decimal
  end
end
