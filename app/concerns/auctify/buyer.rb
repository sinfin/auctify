# frozen_string_literal: true

module Auctify
  module Buyer
    extend ActiveSupport::Concern

    included do
      has_many :purchases, as: :buyer, class_name: "Auctify::Sale::Base"
    end
  end
end
