# frozen_string_literal: true

class AddCommissionAndContractToAuctifySales < ActiveRecord::Migration[6.0]
  def change
    add_column :auctify_sales, :contract_number, :string
    add_column :auctify_sales, :commission_in_percent, :integer
  end
end
