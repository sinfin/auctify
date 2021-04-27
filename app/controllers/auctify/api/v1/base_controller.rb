# frozen_string_literal: true

module Auctify
  module Api
    module V1
      class BaseController < ApplicationController
        include Folio::ApiControllerBase

        # TODO handle authorization here if needed
      end
    end
  end
end
