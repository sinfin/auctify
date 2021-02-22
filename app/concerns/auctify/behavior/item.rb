# frozen_string_literal: true

module Auctify
  module Behavior
    module Item
      extend ActiveSupport::Concern

      include Auctify::Behavior::Base

      included do
        has_many :sales, as: :item, class_name: "Auctify::Sale::Base"
        has_many :auctions, as: :item, class_name: "Auctify::Sale::Auction"
        has_many :retail_sales, as: :item, class_name: "Auctify::Sale::Retail"
      end
    end
  end
end
