# frozen_string_literal: true

module Auctify
  module Behavior
    module Base
      extend ActiveSupport::Concern

      def auctify_id
        "#{self.class.name}@#{id}"
      end

      def object_from_auctify_id(auctify_id)
        return nil if auctify_id.blank?

        klass, id = auctify_id.to_s.split("@")
        klass.constantize.find(id)
      end
    end
  end
end
