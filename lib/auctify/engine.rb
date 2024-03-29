# frozen_string_literal: true

require "aasm"
require "with_advisory_lock"
require_relative "../../app/models/auctify/behaviors"

module Auctify
  class Engine < ::Rails::Engine
    # we choose not to use this `isolate_namespace Auctify`
    # there was problem with routes when using it from main app,
    # (`url_for(Auctify::SalesPack)` => `NoMethodError: sales_pack_url`)

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
