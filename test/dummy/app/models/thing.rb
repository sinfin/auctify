# frozen_string_literal: true

class Thing < ApplicationRecord
  belongs_to :owner, class_name: "User", inverse_of: :things
end
