# frozen_string_literal: true

class AddAuctionProlongingLimitToSalesPacks < ActiveRecord::Migration[6.1]
  def change
    add_column :auctify_sales_packs, :auction_prolonging_limit, :integer
  end
end
