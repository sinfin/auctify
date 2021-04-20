# frozen_string_literal: true

module Auctify
  module ApplicationHelper
    include Auctify::Engine.routes.url_helpers
    # line above somehow breaks url generation in forms from main_app
    # so we nedd to ensure main_app supremacy
    include Rails.application.routes.url_helpers
  end
end
