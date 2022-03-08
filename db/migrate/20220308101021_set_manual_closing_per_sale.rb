# frozen_string_literal: true

class SetManualClosingPerSale < ActiveRecord::Migration[6.1]
  def change
    remove_column :auctify_sales_packs, :sales_closed_manually, :boolean, default: false

    add_column :auctify_sales, :must_be_closed_manually, :boolean, default: false
    add_index :auctify_sales, :must_be_closed_manually
  end
end
