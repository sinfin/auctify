# frozen_string_literal: true

class CleanUser < ApplicationRecord
  def to_label
    name
  end
end
