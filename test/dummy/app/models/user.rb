# frozen_string_literal: true

class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable
  has_many :things, foreign_key: :owner_id, dependent: :destroy, inverse_of: :owner

  auctify_as :seller, :buyer

  def to_label
    name
  end
end
