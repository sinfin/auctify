# frozen_string_literal: true

class AddDontConfirmBidsToRegistrations < ActiveRecord::Migration[6.0]
  def change
    add_column :auctify_bidder_registrations, :dont_confirm_bids, :boolean, default: false
  end
end
