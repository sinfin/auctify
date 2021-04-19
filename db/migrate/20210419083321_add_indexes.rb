# frozen_string_literal: true

class AddIndexes < ActiveRecord::Migration[6.0]
  def change
    add_index :auctify_sales, :published_at
    add_index :auctify_sales, :position

    add_index :auctify_sales_packs, :position
    add_index :auctify_sales_packs, :slug
    add_index :auctify_sales_packs, :published
  end
end
