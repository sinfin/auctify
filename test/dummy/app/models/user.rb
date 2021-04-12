# frozen_string_literal: true

class User < ApplicationRecord
  has_many :things, foreign_key: :owner_id, dependent: :destroy, inverse_of: :owner

  auctify_as :seller, :buyer

  def to_label
    name
  end
end
