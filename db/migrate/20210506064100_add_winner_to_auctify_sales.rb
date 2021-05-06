# frozen_string_literal: true

class AddWinnerToAuctifySales < ActiveRecord::Migration[6.0]
  def change
    add_reference :auctify_sales, :winner, polymorphic: true, null: true
  end
end
