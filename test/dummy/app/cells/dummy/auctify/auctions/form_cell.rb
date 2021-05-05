# frozen_string_literal: true

class Dummy::Auctify::Auctions::FormCell < ApplicationCell
  def serialized_model
    if options[:bid] && options[:bid].errors
      {
        errors: options[:bid].errors.full_messages.map do |msg|
          {
            status: 400,
            title: "ActiveRecord::RecordInvalid",
            detail: msg,
          }
        end
      }.to_json
    else
      Auctify::Sale::AuctionSerializer.new(model).serializable_hash.to_json
    end
  end
end
