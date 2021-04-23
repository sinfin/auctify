# frozen_string_literal: true

class ApplicationRecord < ActiveRecord::Base
  include Folio::Filterable
  include Folio::NillifyBlanks
  include Folio::RecursiveSubclasses
  include Folio::Sortable
  include Folio::ToLabel

  scope :ordered, -> { order(id: :desc) }

  self.abstract_class = true
end
