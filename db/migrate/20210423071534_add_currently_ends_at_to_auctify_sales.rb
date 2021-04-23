class AddCurrentlyEndsAtToAuctifySales < ActiveRecord::Migration[6.0]
  def change
    add_column :auctify_sales, :currently_ends_at, :datetime, index: true
  end
end
