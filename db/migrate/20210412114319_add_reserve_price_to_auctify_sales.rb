class AddReservePriceToAuctifySales < ActiveRecord::Migration[6.0]
  def change
    add_column :auctify_sales, :reserve_price, :decimal, null: true
  end
end
