# frozen_string_literal: true

require "test_helper"

class ThingTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end

  test "knows its owner" do
    u = User.create!(name: "John")
    t = Thing.create!(owner: u, name: "Velké kulové")

    t.reload
    assert_equal u.name, t.owner.name
  end
end
