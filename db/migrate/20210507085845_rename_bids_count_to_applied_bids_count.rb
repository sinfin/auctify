# frozen_string_literal: true

class RenameBidsCountToAppliedBidsCount < ActiveRecord::Migration[6.0]
  def change
    rename_column :auctify_sales, :bids_count, :applied_bids_count
  end
end
