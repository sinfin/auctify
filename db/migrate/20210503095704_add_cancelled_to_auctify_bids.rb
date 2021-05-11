# frozen_string_literal: true

class AddCanceledToAuctifyBids < ActiveRecord::Migration[6.0]
  def change
    add_column :auctify_bids, :cancelled, :boolean, default: false, index: true
  end
end
