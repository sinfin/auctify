# frozen_string_literal: true

require "test_helper"

module Auctify
  class SalesPackTest < ActiveSupport::TestCase
    test "dates_to_label" do
      pack = Auctify::SalesPack.new(start_date: Date.new(2021, 1, 1), end_date: Date.new(2021, 1, 3))
      assert_equal("1.–3. 1. 21", pack.dates_to_label)

      pack = Auctify::SalesPack.new(start_date: Date.new(2021, 1, 29), end_date: Date.new(2021, 2, 1))
      assert_equal("29. 1. – 1. 2. 21", pack.dates_to_label)

      pack = Auctify::SalesPack.new(start_date: Date.new(2020, 12, 30), end_date: Date.new(2021, 1, 2))
      assert_equal("30. 12. 20 – 2. 1. 21", pack.dates_to_label)
    end
  end
end
