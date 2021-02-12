# frozen_string_literal: true

module Auctify
  module Seller
    extend ActiveSupport::Concern

    included do
      def sales
        []
      end
    end
  end
end
