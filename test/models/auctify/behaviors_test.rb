# frozen_string_literal: true

require "test_helper"

module Auctify
  class BehaviorsTest < ActiveSupport::TestCase
    setup do
      class TestUser < User; end # so it not propagate class_eval to User class
    end

    test "`.auctify_as` adds methods from listed concerns" do
      assert_not TestUser.new(name: "Krutibrko").respond_to?(:sales)
      assert_not TestUser.new(name: "Krutibrko").respond_to?(:purchases)

      TestUser.class_eval do
        auctify_as :seller, :buyer
      end

      assert TestUser.new(name: "Krutibrko").respond_to?(:sales)
      assert TestUser.new(name: "Krutibrko").respond_to?(:purchases)
    end
  end
end
