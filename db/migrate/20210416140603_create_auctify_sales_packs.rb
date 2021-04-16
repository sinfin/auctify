# frozen_string_literal: true

class CreateAuctifySalesPacks < ActiveRecord::Migration[6.0]
  def change
    create_table :auctify_sales_packs do |t|
      t.string :title
      t.text :description
      t.integer :position, default: 0
      t.string :slug
      t.string :time_frame
      t.string :place
      t.boolean :published, default: false

      t.timestamps
    end
  end
end
