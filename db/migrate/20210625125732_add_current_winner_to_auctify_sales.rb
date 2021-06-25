# frozen_string_literal: true

class AddCurrentWinnerToAuctifySales < ActiveRecord::Migration[6.0]
  def change
    add_reference :auctify_sales, :current_winner, polymorphic: true, null: true, index: false
  end
end
