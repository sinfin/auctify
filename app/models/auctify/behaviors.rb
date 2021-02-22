# frozen_string_literal: true

module Auctify
  module Behaviors
    @@auctified_classes = {}
    # I borrowed this from Devise

    # Include the chosen auctify behaviors in your model:
    #
    #   auctify_as :seller, :buyer
    #
    def auctify_as(*behaviors)
      selected_behaviors = behaviors.map(&:to_sym).uniq

      selected_behaviors.each do |bhv|
        behavior = Auctify::Behavior::const_get(bhv.to_s.classify) # rubocop:disable Style/ColonMethodCall
        include behavior
        Rails.logger.info("Auctifiyng #{self} as #{bhv}: #{@@auctified_classes}")
        @@auctified_classes[bhv] = ((@@auctified_classes[bhv] || []) + [self]).sort_by { |c| c.name }
      end
    end

    def self.registered_classes_as(behavior)
      @@auctified_classes[behavior] || []
    end
  end
end
