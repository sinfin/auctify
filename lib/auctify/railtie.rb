# frozen_string_literal: true

module Auctify
  class Railtie < Rails::Railtie
    # I did not found way, how to chec for presence of Yabeda::Prometheus::Exporter in middleware
    if require "yabeda/prometheus"
      initializer "auctify.railtie_initialization" do |main_app|
        main_app.middleware.use ::Yabeda::Prometheus::Exporter
      end
    end
  end
end

require "yabeda_config.rb"
