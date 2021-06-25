# frozen_string_literal: true

require "test_helper"

class ThingTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end

  test "knows its owner" do
    u = User.create!(name: "John", email: "jd@here.com", password: "password")
    t = Thing.create!(owner: u, name: "Velké kulové")

    t.reload
    assert_equal u.name, t.owner.name
  end

  test "recognizes its latest published sale" do
    apple = things(:apple)
    fixture_sale = apple.sales.first
    assert fixture_sale.auctioned_successfully?

    assert_equal fixture_sale, apple.last_published_sale

    latest_sale = Auctify::Sale::Base.create!(seller: users(:adam), item: apple, offered_price: 555)

    # latest is not yet published!
    assert_equal fixture_sale, apple.last_published_sale

    assert latest_sale.publish!

    assert_equal latest_sale, apple.last_published_sale

    # and check for assoc includes

    Thing.all.includes(:last_published_sale).to_a
  end
end
