# frozen_string_literal: true

require "yabeda/prometheus"

module Auctify
  class Railtie < Rails::Railtie
    initializer "my_railtie.configure_rails_initialization" do |app|
      app.middleware.use ::Yabeda::Prometheus::Exporter
    end
  end
end
