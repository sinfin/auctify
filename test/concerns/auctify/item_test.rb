# frozen_string_literal: true

require "test_helper"

module Auctify
  class ItemTest < ActiveSupport::TestCase
    setup do
      class ItemTestThing < CleanThing; end # so it will not propagate class_eval to Thing class
    end

    test " adds `sales` association" do
      assert_not ItemTestThing.new(name: "Krutibrko").respond_to?(:sales)

      ItemTestThing.class_eval do
        auctify_as :item
      end

      assert ItemTestThing.new(name: "Krutibrko").respond_to?(:sales)
    end

    test "knows its #auctify_id" do
      item = things(:apple)
      assert_equal "#{item.class.name}@#{item.id}", item.auctify_id
    end
  end
end
