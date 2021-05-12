# frozen_string_literal: true

class AddSoldAtToAuctifySales < ActiveRecord::Migration[6.0]
  def change
    add_column :auctify_sales, :sold_at, :datetime, default: nil, null: true
  end
end
