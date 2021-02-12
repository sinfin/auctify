# frozen_string_literal: true

module Auctify
  class Sale < ApplicationRecord
    belongs_to :seller, polymorphic: true
    belongs_to :buyer, polymorphic: true
    belongs_to :item, polymorphic: true
  end
end
