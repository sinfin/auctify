# frozen_string_literal: true

module Auctify
  class ApplicationController < ActionController::Base
    protect_from_forgery with: :exception
    include Auctify::ApplicationHelper
  end
end
