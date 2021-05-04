# frozen_string_literal: true

module Auctify
  class Configuration
    attr_accessor :autoregister_as_bidders_all_instances_of_classes,
                  :auction_prolonging_limit,
                  :job_to_run_after_bidding_ends,
                  :auctioneer_commission_in_percent


    def initialize
      # set defaults here
      @autoregister_as_bidders_all_instances_of_classes = []
      @auction_prolonging_limit = 2.minutes
      @job_to_run_after_bidding_ends = nil
      @auctioneer_commission_in_percent = 1 # %
    end
  end


  def self.configuration
    @configuration ||= Auctify::Configuration.new
  end

  def self.configure
    yield(configuration)
  end
end
