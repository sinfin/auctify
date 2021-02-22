# frozen_string_literal: true

module Auctify
  module Behavior
    module Buyer
      extend ActiveSupport::Concern

      include Auctify::Behavior::Base

      included do
        has_many :purchases, as: :buyer, class_name: "Auctify::Sale::Base"
      end
    end
  end
end
