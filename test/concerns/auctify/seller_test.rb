# frozen_string_literal: true

require "test_helper"

module Auctify
  class SellerTest < ActiveSupport::TestCase
    test " adds `sales` association" do
      assert_not User.new(name: "Krutibrko").respond_to?(:sales)

      User.class_eval do
        auctify_as :seller
      end

      assert User.new(name: "Krutibrko").respond_to?(:sales)
    end
  end
end
