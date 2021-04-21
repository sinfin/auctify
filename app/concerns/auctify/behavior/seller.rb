# frozen_string_literal: true

module Auctify
  module Behavior
    module Seller
      extend ActiveSupport::Concern

      include Auctify::Behavior::Base

      included do
        has_many :sales, as: :seller, class_name: "Auctify::Sale::Base"
        has_many :auction_sales, as: :seller, class_name: "Auctify::Sale::Auction"
        has_many :retail_sales, as: :seller, class_name: "Auctify::Sale::Retail"

        def offer_to_sale!(item, options = {})
          assoc = options[:in] == :auction ? auction_sales : retail_sales
          assoc.create!(item: item,
                        seller: self,
                        buyer: nil,
                        offered_price: options[:price])
        end
      end
    end
  end
end
