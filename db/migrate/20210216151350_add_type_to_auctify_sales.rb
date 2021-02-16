# frozen_string_literal: true

class AddTypeToAuctifySales < ActiveRecord::Migration[6.0]
  def change
    add_column :auctify_sales, :type, :string, default: "Auctify::Sale::Base", index: true
  end
end
