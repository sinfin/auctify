# frozen_string_literal: true

class ChangeColumnPublishedOnAuctifySale < ActiveRecord::Migration[6.0]
  def up
    add_column :auctify_sales, :published, :boolean, default: false, index: true
    execute("UPDATE auctify_sales set published = TRUE where published_at IS NOT NULL;")
    remove_column :auctify_sales, :published_at
  end

  def down
    add_column :auctify_sales, :published_at, :datetime
    execute("UPDATE auctify_sales set published_at = NOW() WHERE published = TRUE ;")
    remove_column :auctify_sales, :published
  end
end
