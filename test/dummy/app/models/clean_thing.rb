# frozen_string_literal: true

class CleanThing < ApplicationRecord
  def to_label
    name
  end
end
