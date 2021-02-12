# frozen_string_literal: true

module Auctify
  module Buyer
    extend ActiveSupport::Concern

    included do
      def purchases
        []
      end
    end
  end
end
