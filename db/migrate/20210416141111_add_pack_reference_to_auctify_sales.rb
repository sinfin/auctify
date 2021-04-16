# frozen_string_literal: true

class AddPackReferenceToAuctifySales < ActiveRecord::Migration[6.0]
  def change
    add_reference :auctify_sales, :pack, references: :auctify_sales_packs, index: true
  end
end
