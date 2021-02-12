# frozen_string_literal: true

require "test_helper"

module Auctify
  class BuyerTest < ActiveSupport::TestCase
    setup do
      class BuyerTestUser < User; end # so it not propagate class_eval to User class
    end

    test " adds `purchases` association" do
      assert_not BuyerTestUser.new(name: "Krutibrko").respond_to?(:purchases)

      BuyerTestUser.class_eval do
        auctify_as :buyer
      end

      assert BuyerTestUser.new(name: "Krutibrko").respond_to?(:purchases)
    end
  end
end
