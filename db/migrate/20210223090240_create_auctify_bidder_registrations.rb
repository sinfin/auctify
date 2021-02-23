# frozen_string_literal: true

class CreateAuctifyBidderRegistrations < ActiveRecord::Migration[6.0]
  def change
    create_table :auctify_bidder_registrations do |t|
      t.references :bidder, polymorphic: true, null: false,
index: { name: "index_auctify_bidder_registrations_on_bidder" }
      t.references :auction, null: false, foreign_key: { to_table: "auctify_sales" }
      t.string :aasm_state, null: false, default: "pending", index: true
      t.datetime :handled_at

      t.timestamps
    end
  end
end
