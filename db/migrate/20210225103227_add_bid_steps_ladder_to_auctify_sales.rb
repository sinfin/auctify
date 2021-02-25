# frozen_string_literal: true

class AddBidStepsLadderToAuctifySales < ActiveRecord::Migration[6.0]
  def change
    add_column :auctify_sales, :bid_steps_ladder, :jsonb, null: true
  end
end
