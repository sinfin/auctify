# frozen_string_literal: true

module Auctify
  class Configuration
    attr_accessor :autoregister_as_bidders_all_instances_of_classes,

    def initialize
      # set defaults here
      @autoregister_as_bidders_all_instances_of_classes = []
    end
  end

  class << self
    attr_accessor :configuration
  end

  def self.configure
    self.configuration ||= Auctify::Configuration.new
    yield(configuration)
  end
end
