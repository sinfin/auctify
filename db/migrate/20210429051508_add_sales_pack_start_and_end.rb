# frozen_string_literal: true

class AddSalesPackStartAndEnd < ActiveRecord::Migration[6.0]
  def change
    add_column :auctify_sales_packs, :start_date, :date
    add_column :auctify_sales_packs, :end_date, :date

    add_column :auctify_sales_packs, :sales_interval, :integer, default: 3

    add_column :auctify_sales_packs, :sales_beginning_hour, :integer, default: 20
    add_column :auctify_sales_packs, :sales_beginning_minutes, :integer, default: 0

    remove_column :auctify_sales_packs, :time_frame, :string
  end
end
