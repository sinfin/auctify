# frozen_string_literal: true

class AddNumberToAuctifySales < ActiveRecord::Migration[6.0]
  def change
    add_column :auctify_sales, :number, :string
  end
end
