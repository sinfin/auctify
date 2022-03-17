# frozen_string_literal: true

class AddBiddingsLockedToSales < ActiveRecord::Migration[6.1]
  def change
    add_column :auctify_sales, :bidding_locked_at, :datetime
    add_reference :auctify_sales, :bidding_locked_by, polymorphic: true
  end
end
