# frozen_string_literal: true

module Auctify
  class Configuration
    attr_accessor :autoregister_as_bidders_all_instances_of_classes,
                  :auction_prolonging_limit,
                  :auctioneer_commission_in_percent,
                  :autofinish_auction_after_bidding,
                  :when_to_notify_bidders_before_end_of_bidding,
                  :default_bid_steps_ladder,
                  :restrict_overbidding_yourself_to_max_price_increasing,
                  :require_bids_to_be_rounded_to,
                  :allow_changes_on_auction_with_bids_for_attributes


    def initialize
      # set defaults here
      @autoregister_as_bidders_all_instances_of_classes = []
      @auction_prolonging_limit = 2.minutes
      @auctioneer_commission_in_percent = 1 # %
      @autofinish_auction_after_bidding = false
      @when_to_notify_bidders_before_end_of_bidding = nil # no notifying
      @default_bid_steps_ladder = { 0.. => 1 }
      @restrict_overbidding_yourself_to_max_price_increasing = true
      @require_bids_to_be_rounded_to = 1
      @allow_changes_on_auction_with_bids_for_attributes = []
    end

    def autoregistering_for?(instance)
      return false if instance.blank?

      autoregister_as_bidders_all_instances_of_classes.include?(instance.class.name)
    end
  end


  def self.configuration
    @configuration ||= Auctify::Configuration.new
  end

  def self.configure
    yield(configuration)

    class_names = configuration.autoregister_as_bidders_all_instances_of_classes.collect { |klass| klass.is_a?(String) ? klass : klass.name }
    configuration.autoregister_as_bidders_all_instances_of_classes = class_names.sort
  end
end
