# frozen_string_literal: true

class AddSalesBoolIndices < ActiveRecord::Migration[6.0]
  def change
    add_index :auctify_sales, :published
    add_index :auctify_sales, :featured
    change_column_default :auctify_sales, :featured, false
  end
end
