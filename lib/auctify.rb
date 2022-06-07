# frozen_string_literal: true

if defined?(Rails::Railtie)
  require "auctify/railtie"
  require "yabeda_config.rb"
end

require "auctify/engine"
require "auctify/configuration"

module Auctify
end
