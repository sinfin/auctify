# frozen_string_literal: true

module Auctify
  module Api
    module V1
      class BaseController < ApplicationController
        include Folio::ApiControllerBase

        # TODO handle authorization here if needed

        private
          def global_namespace_path
            @global_namespace_path ||= global_namespace.underscore
          end

          def global_namespace
            @global_namespace ||= Rails.application.class.name.deconstantize
          end
      end
    end
  end
end
