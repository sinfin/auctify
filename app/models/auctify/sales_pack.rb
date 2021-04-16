# frozen_string_literal: true

module Auctify
  class SalesPack < ApplicationRecord
    has_many :sales, class_name: "Auctify::Sale::Base", foreign_key: :pack_id, inverse_of: :pack, dependent: :nullify
  end
end
