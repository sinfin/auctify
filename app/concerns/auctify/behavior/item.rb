# frozen_string_literal: true

module Auctify
  module Behavior
    module Item
      extend ActiveSupport::Concern

      include Auctify::Behavior::Base

      included do
        has_many :sales, class_name: "Auctify::Sale::Base", foreign_key: :item_id, inverse_of: :item
        has_many :auction_sales, class_name: "Auctify::Sale::Auction", foreign_key: :item_id, inverse_of: :item
        has_many :retail_sales, class_name: "Auctify::Sale::Retail", foreign_key: :item_id, inverse_of: :item

        c_name = self.name
        Auctify::Sale::Base.class_eval do
          belongs_to :item, class_name: c_name, counter_cache: :sales_count
        end
      end
    end
  end
end
