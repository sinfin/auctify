# frozen_string_literal: true

require "test_helper"

class TestUserTest < ActiveSupport::TestCase
  test "the truth" do
    new_user.respond_to?(:name)
  end
end
