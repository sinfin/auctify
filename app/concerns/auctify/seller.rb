# frozen_string_literal: true

module Auctify
  module Seller
    extend ActiveSupport::Concern

    included do
      has_many :sales, as: :seller, class_name: "Auctify::Sale::Base"

      def offer_to_sale!(item, options)
        sales.create!(item: item,
                      seller: self,
                      buyer: nil,
                      offered_price: options[:price])
      end
    end
  end
end
