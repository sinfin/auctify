# frozen_string_literal: true

module Auctify
  class Engine < ::Rails::Engine
    isolate_namespace Auctify
  end
end

# trick borrowed from Devise
ActiveSupport.on_load(:active_record) do
  extend Auctify::Behaviors
end
