# frozen_string_literal: true

class UpdateSalesFeaturable < ActiveRecord::Migration[6.1]
  def up
    rename_column :auctify_sales, :featured, :featured_tmp_boolean

    add_column :auctify_sales, :featured, :integer, default: nil
    add_index :auctify_sales, :featured

    execute("UPDATE auctify_sales SET featured = 1 WHERE featured_tmp_boolean = TRUE;")

    remove_column :auctify_sales, :featured_tmp_boolean
  end

  def down
    rename_column :auctify_sales, :featured, :featured_tmp_integer

    add_column :auctify_sales, :featured, :boolean, default: false
    add_index :auctify_sales, :featured

    execute("UPDATE auctify_sales SET featured = TRUE WHERE featured_tmp_integer IS NOT NULL;")

    remove_column :auctify_sales, :featured_tmp_integer
  end
end
