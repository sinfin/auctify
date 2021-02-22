# frozen_string_literal: true

class AddPublishedAtToAuctifySale < ActiveRecord::Migration[6.0]
  def change
    add_column :auctify_sales, :published_at, :datetime, default: :null
  end
end
