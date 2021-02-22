# frozen_string_literal: true

module Auctify
  module SalesHelper
    def auctify_id_options_for_select(type)
      opts = []

      Auctify::Behaviors.registered_classes_as(type).each do |klass|
        opts += klass.all.collect { |obj| [obj.name, obj.auctify_id] }
      end

      opts
    end
  end
end
