# frozen_string_literal: true

class RemovingPolymorphicAssocSaleToItem < ActiveRecord::Migration[6.0]
  def change
    remove_column :auctify_sales, :item_type, :string
  end
end
