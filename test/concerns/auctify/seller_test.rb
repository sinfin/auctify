# frozen_string_literal: true

require "test_helper"

module Auctify
  class SellerTest < ActiveSupport::TestCase
    setup do
      class SellerTestUser < User; end # so it not propagate class_eval to User class
    end

    test " adds `sales` association" do
      assert_not SellerTestUser.new(name: "Krutibrko").respond_to?(:sales)

      SellerTestUser.class_eval do
        auctify_as :seller
      end

      assert SellerTestUser.new(name: "Krutibrko").respond_to?(:sales)
    end
  end
end
