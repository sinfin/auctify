# frozen_string_literal: true

class AddIndexToSalesEndsAt < ActiveRecord::Migration[6.0]
  def change
    add_index :auctify_sales, :ends_at
  end
end
