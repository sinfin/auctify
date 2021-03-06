# frozen_string_literal: true

require "test_helper"

module Auctify
  class BuyerTest < ActiveSupport::TestCase
    setup do
      class BuyerCleanUser < CleanUser; end # so it will not propagate class_eval to User class
    end

    test " adds `purchases` association" do
      assert_not BuyerCleanUser.new(name: "Krutibrko").respond_to?(:purchases)

      BuyerCleanUser.class_eval do
        auctify_as :buyer
      end

      assert BuyerCleanUser.new(name: "Krutibrko").respond_to?(:purchases)
    end

    test "knows its #auctify_id" do
      buyer = users(:eve)
      assert_equal "#{buyer.class.name}@#{buyer.id}", buyer.auctify_id
    end
  end
end
