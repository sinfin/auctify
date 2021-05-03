# frozen_string_literal: true

class AddSalesSlug < ActiveRecord::Migration[6.0]
  def change
    add_column :auctify_sales, :slug, :string
    add_index :auctify_sales, :slug, unique: true

    remove_index :auctify_sales_packs, :slug
    add_index :auctify_sales_packs, :slug, unique: true
  end
end
