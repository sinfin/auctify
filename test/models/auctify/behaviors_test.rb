# frozen_string_literal: true

require "test_helper"

module Auctify
  class BehaviorsTest < ActiveSupport::TestCase
    setup do
      class TestUser < CleanUser; end # so it will not propagate class_eval to User class
    end

    test "`.auctify_as` adds methods from listed concerns" do
      assert_not TestUser.new(name: "Krutibrko").respond_to?(:sales)
      assert_not TestUser.new(name: "Krutibrko").respond_to?(:purchases)
      assert_not_includes Auctify::Behaviors.registered_classes_as(:seller), TestUser
      assert_not_includes Auctify::Behaviors.registered_classes_as(:buyer), TestUser

      TestUser.class_eval do
        auctify_as :seller, :buyer
      end

      assert TestUser.new(name: "Krutibrko").respond_to?(:sales)
      assert TestUser.new(name: "Krutibrko").respond_to?(:purchases)
      assert_equal "Auctify::BehaviorsTest::TestUser@5", TestUser.new(name: "Krutibrko", id: 5).auctify_id
      assert_includes Auctify::Behaviors.registered_classes_as(:seller), TestUser
      assert_includes Auctify::Behaviors.registered_classes_as(:buyer), TestUser
    end

    test "`.auctify_as` raises exception on unknown concerns" do
      module Hacker
        def hack; true; end
      end

      assert_not TestUser.new(name: "Krutibrko").respond_to?(:hack)

      ex = assert_raises(NameError) do
        TestUser.class_eval do
          auctify_as :hacker
        end
      end

      assert_equal "uninitialized constant Auctify::Behavior::Hacker", ex.message

      assert_not TestUser.new(name: "Krutibrko").respond_to?(:hack)
      assert_equal [], Auctify::Behaviors.registered_classes_as(:hacker)
    end
  end
end
