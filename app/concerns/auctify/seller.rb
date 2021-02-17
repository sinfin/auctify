# frozen_string_literal: true

module Auctify
  module Seller
    extend ActiveSupport::Concern

    included do
      has_many :sales, as: :seller, class_name: "Auctify::Sale::Base"
      has_many :auctions, as: :seller, class_name: "Auctify::Sale::Auction"
      has_many :retail_sales, as: :seller, class_name: "Auctify::Sale::Retail"

      def offer_to_sale!(item, options = {})
        assoc = options[:in] == :auction ? auctions : retail_sales
        assoc.create!(item: item,
                      seller: self,
                      buyer: nil,
                      offered_price: options[:price])
      end
    end
  end
end
