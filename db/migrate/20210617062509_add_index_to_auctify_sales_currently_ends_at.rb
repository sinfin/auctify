# frozen_string_literal: true

class AddIndexToAuctifySalesCurrentlyEndsAt < ActiveRecord::Migration[6.0]
  def change
    add_index :auctify_sales, :currently_ends_at
  end
end
