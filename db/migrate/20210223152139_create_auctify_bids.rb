# frozen_string_literal: true

class CreateAuctifyBids < ActiveRecord::Migration[6.0]
  def change
    create_table :auctify_bids do |t|
      t.references :registration, null: false, foreign_key: { to_table: "auctify_bidder_registrations" }
      t.decimal :price, null: false, precision: 12, scale: 2
      t.decimal :max_price, null: true, precision: 12, scale: 2

      t.timestamps
    end
  end
end
