# frozen_string_literal: true

require "aasm"
require_relative "../../app/models/auctify/behaviors"

module Auctify
  class Engine < ::Rails::Engine
    isolate_namespace Auctify

    initializer :append_migrations do |app|
      unless app.root.to_s.include? root.to_s
        config.paths["db/migrate"].expanded.each do |expanded_path|
          app.config.paths["db/migrate"] << expanded_path
        end
      end
    end
  end
end

# trick borrowed from Devise
ActiveSupport.on_load(:active_record) do
  extend Auctify::Behaviors
end
