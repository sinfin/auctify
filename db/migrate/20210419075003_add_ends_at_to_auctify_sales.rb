# frozen_string_literal: true

class AddEndsAtToAuctifySales < ActiveRecord::Migration[6.0]
  def change
    add_column :auctify_sales, :ends_at, :datetime, null: true
  end
end
