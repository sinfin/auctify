# frozen_string_literal: true

require "test_helper"

module Auctify
  class ItemTest < ActiveSupport::TestCase
    setup do
      class ItemTestThing < Thing; end # so it not propagate class_eval to Thing class
    end

    test " adds `sales` association" do
      assert_not ItemTestThing.new(name: "Krutibrko").respond_to?(:sales)

      ItemTestThing.class_eval do
        auctify_as :item
      end

      assert ItemTestThing.new(name: "Krutibrko").respond_to?(:sales)
    end
  end
end
