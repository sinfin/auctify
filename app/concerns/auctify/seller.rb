# frozen_string_literal: true

module Auctify
  module Seller
    extend ActiveSupport::Concern

    included do
      has_many :sales, as: :seller, class_name: "Auctify::Sale"

      def sell(item, options)
        raise "Not Auctified Item: #{item.class}" unless item.respond_to?(:sales) # TODO make it to check include concern
        Auctify::Sale.create(item: item, seller: self, buyer: self) # TODO : fix buyer, should be blank!
      end
    end
  end
end
