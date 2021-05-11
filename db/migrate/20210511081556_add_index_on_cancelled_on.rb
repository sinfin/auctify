# frozen_string_literal: true

class AddIndexOnCancelledOn < ActiveRecord::Migration[6.0]
  def change
    add_index :auctify_bids, :cancelled
  end
end
