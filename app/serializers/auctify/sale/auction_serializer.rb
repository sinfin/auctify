# frozen_string_literal: true

class Auctify::Sale::AuctionSerializer
  include FastJsonapi::ObjectSerializer

  attributes :id,
             :current_price,
             :current_minimal_bid,
             :currently_ends_at,
             :ends_at,
             :open_for_bids?

  attribute :current_winner do |auction|
    winner = auction.current_winner
    {
      id: winner.id,
      auctify_id: winner.auctify_id,
      to_label: winner.to_label
    }
  end





  # assert_equal auction.current_winner.id, json_attributes["current_winner"]["id"]
  # assert_equal auction.current_winner.auctify_id, json_attributes["current_winner"]["auctify_id"]
  # assert_equal auction.current_winner.to_label, json_attributes["current_winner"]["to_label"]
  # assert_equal auction.current_price, json_attributes["current_price"]
  # assert_equal auction.current_minimal_bid, json_attributes["current_minimal_bid"]
  # assert_equal auction.ends_at, json_attributes["ends_at"]
  # assert_equal auction.currently_ends_at, json_attributes["currently_ends_at"]
  # assert_equal auction.open_for_bids?, json_attributes["open_for_bids?"]


  # attributes :name, :year
  # has_many :actors
  # belongs_to :owner, record_type: :user
  # belongs_to :movie_ty
  # # link :url do |object|
  # #   Rails.application
  # #        .routes
  # #        .url_helpers
  # #        .url_for([object, only_path: true])
  # # end
end
