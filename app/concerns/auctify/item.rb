# frozen_string_literal: true

module Auctify
  module Item
    extend ActiveSupport::Concern

    included do
      has_many :sales, as: :item, class_name: "Auctify::Sale::Base"
    end
  end
end
