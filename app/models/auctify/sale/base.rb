# frozen_string_literal: true

module Auctify
  module Sale
    class Base < ApplicationRecord
      self.table_name = "auctify_sales"

      belongs_to :seller, polymorphic: true
      belongs_to :buyer, polymorphic: true
      belongs_to :item, polymorphic: true
    end
  end
end

# == Schema Information
#
# Table name: auctify_sales
#
#  id          :integer          not null, primary key
#  buyer_type  :string
#  item_type   :string           not null
#  seller_type :string           not null
#  type        :string           default("Auctify::Sale::Base")
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  buyer_id    :integer
#  item_id     :integer          not null
#  seller_id   :integer          not null
#
# Indexes
#
#  index_auctify_sales_on_buyer_type_and_buyer_id    (buyer_type,buyer_id)
#  index_auctify_sales_on_item_type_and_item_id      (item_type,item_id)
#  index_auctify_sales_on_seller_type_and_seller_id  (seller_type,seller_id)
#
