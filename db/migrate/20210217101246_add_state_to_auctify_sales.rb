# frozen_string_literal: true

class AddStateToAuctifySales < ActiveRecord::Migration[6.0]
  def change
    add_column :auctify_sales, :aasm_state, :string, default: "offered", null: false, index: true
  end
end
