class AddBidsCountToAuctifySales < ActiveRecord::Migration[6.0]
  def change
    add_column :auctify_sales, :bids_count, :integer, default: 0
  end
end
