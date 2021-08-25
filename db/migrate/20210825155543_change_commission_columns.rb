# frozen_string_literal: true

class ChangeCommissionColumns < ActiveRecord::Migration[6.1]
  def change
    rename_column :auctify_sales, :commission_in_percent, :seller_commission_in_percent
    add_column :auctify_sales, :buyer_commission_in_percent, :integer
  end
end
