# frozen_string_literal: true

class AddAutobidToAuctifyBids < ActiveRecord::Migration[6.1]
  def up
    add_column :auctify_bids, :autobid, :boolean, default: false
    Auctify::AutobidFillerJob.perform_later
  end

  def down
    remove_column :auctify_bids, :autobid
  end
end
