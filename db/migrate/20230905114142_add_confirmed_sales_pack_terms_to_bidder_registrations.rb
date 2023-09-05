# frozen_string_literal: true

class AddConfirmedSalesPackTermsToBidderRegistrations < ActiveRecord::Migration[6.1]
  def change
    add_column :auctify_bidder_registrations, :confirmed_sales_pack_terms, :boolean, default:  false

    execute "UPDATE auctify_bidder_registrations SET confirmed_sales_pack_terms = true WHERE dont_confirm_bids = true;"
  end
end
