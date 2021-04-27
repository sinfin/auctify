# frozen_string_literal: true

class AddFeaturedToAuctifySales < ActiveRecord::Migration[6.0]
  def change
    add_column :auctify_sales, :featured, :boolean, index: true
  end
end
