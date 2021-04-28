# frozen_string_literal: true

class AddSalesCountToThings < ActiveRecord::Migration[6.0]
  def change
    add_column :things, :sales_count, :integer, default: 0
  end
end
