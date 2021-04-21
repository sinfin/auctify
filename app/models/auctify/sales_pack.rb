# frozen_string_literal: true

module Auctify
  class SalesPack < ApplicationRecord
    has_many :sales, class_name: "Auctify::Sale::Base", foreign_key: :pack_id, inverse_of: :pack, dependent: :nullify
    # has_many :items, through: :sales

    validates :title,
              presence: true,
              uniqueness: true

    scope :ordered, -> { order(id: :desc) }

    def items
      @items ||= sales.collect(&:item) # TODO: make it Arel/Association like
      # used_polymorhic_classes = sales.pluck(:item_type).uniq
      # classes_with_table_names = used_polymorhic_classes.collect { |pc| [pc, pc.constantize.table_name] }
    end

    def to_label
      title
    end
  end
end
