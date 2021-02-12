# frozen_string_literal: true

require "test_helper"

module Auctify
  class SellerTest < ActiveSupport::TestCase
    test " adds `sales` association" do
      assert_not TestUser.new(name: "Krutibrko").respond_to?(:sales)

      TestUser.class_eval do
        include Auctify::Seller
      end

      assert TestUser.new(name: "Krutibrko").respond_to?(:sales)
    end
  end
end
