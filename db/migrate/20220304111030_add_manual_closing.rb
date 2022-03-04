# frozen_string_literal: true

class AddManualClosing < ActiveRecord::Migration[6.1]
  def change
    add_column :auctify_sales_packs, :sales_closed_manually, :boolean, default: false

    add_column :auctify_sales, :manually_closed_at, :datetime
    add_reference :auctify_sales, :manually_closed_by, polymorphic: true
  end
end
