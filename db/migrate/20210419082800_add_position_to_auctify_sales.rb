# frozen_string_literal: true

class AddPositionToAuctifySales < ActiveRecord::Migration[6.0]
  def change
    add_column :auctify_sales, :position, :integer
    add_column :auctify_sales_packs, :sales_count, :integer, default: 0
  end
end
