# frozen_string_literal: true

module Auctify
  module Behaviors
    # I borrowed this from Devise

    # Include the chosen auctify behaviors in your model:
    #
    #   auctify_as :seller, :buyer
    #
    def auctify_as(*behaviors)
      selected_behaviors = behaviors.map(&:to_sym).uniq

      selected_behaviors.each do |b|
        behavior = Auctify::const_get(b.to_s.classify) # rubocop:disable Style/ColonMethodCall
        include behavior
      end
    end
  end
end
