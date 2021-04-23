# frozen_string_literal: true

module Auctify
  class SalesPack < ApplicationRecord
    include Folio::FriendlyId

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

# == Schema Information
#
# Table name: auctify_sales_packs
#
#  id          :bigint(8)        not null, primary key
#  title       :string
#  description :text
#  position    :integer          default(0)
#  slug        :string
#  time_frame  :string
#  place       :string
#  published   :boolean          default(FALSE)
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  sales_count :integer          default(0)
#
# Indexes
#
#  index_auctify_sales_packs_on_position   (position)
#  index_auctify_sales_packs_on_published  (published)
#  index_auctify_sales_packs_on_slug       (slug)
#
