# frozen_string_literal: true

class AddCommissionInPercentToSalesPacks < ActiveRecord::Migration[6.0]
  def change
    add_column :auctify_sales_packs, :commission_in_percent, :integer
  end
end
