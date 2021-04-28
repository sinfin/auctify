# frozen_string_literal: true

class AllowSellerToBeNil < ActiveRecord::Migration[6.0]
  def up
    change_column :auctify_sales, :seller_id, :integer, null: true
    change_column :auctify_sales, :seller_type, :string, null: true
  end

  def down
    change_column :auctify_sales, :seller_id, :integer, null: false
    change_column :auctify_sales, :seller_type, :string, null: false
  end
end
