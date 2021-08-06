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

    test "forbid deleting if there are any sales" do
      pack = auctify_sales_packs(:things_from_eden)
      sales = pack.sales.reload
      assert_equal 4, sales.size

      assert_not pack.destroy
      assert_includes pack.errors[:base], "Nemůžu smazat položku protože existuje závislé/ý položky", pack.errors.to_json

      sales.each do |sale|
        if sale.respond_to?(:bids)
          sale.bidder_registrations.each { |br| br.bids.destroy_all }
        end
        sale.destroy!
      end

      assert_equal 0, pack.sales.reload.size
      assert pack.destroy
    end

    test "fill up commission_in_percent from config" do
      original = Auctify.configuration.auctioneer_commission_in_percent
      new_commission = 33

      Auctify.configure { |config| config.auctioneer_commission_in_percent = new_commission }

      assert_equal 33, Auctify::SalesPack.new.commission_in_percent

      Auctify.configure { |config| config.auctioneer_commission_in_percent = original }
    end

    test "moves all sales according to start_date change" do
      original_start_date = Date.tomorrow
      new_start_date = Date.tomorrow + 1.week

      pack = Auctify::SalesPack.create!(title: "Ready to launch",
                                        start_date: original_start_date,
                                        end_date: original_start_date + 7.days)
      firts_sale = Auctify::Sale::Auction.create!(seller: users(:eve),
                                                  item: things(:apple),
                                                  offered_price: 100.0,
                                                  pack: pack,
                                                  ends_at: pack.start_date.to_time + 1.hour)

      last_sale = Auctify::Sale::Auction.create!(seller: users(:adam),
                                                 item: things(:innocence),
                                                 offered_price: 100.0,
                                                 pack: pack,
                                                 ends_at: pack.end_date.to_time + 1.day - 1.minute)

      assert_equal 2, pack.sales.reload.size

      pack.update(start_date: new_start_date, end_date: new_start_date + 7.days)

      assert_equal new_start_date, pack.reload.start_date
      assert_equal new_start_date + 7.days, pack.end_date

      assert_equal pack.start_date.to_time + 1.hour, firts_sale.reload.ends_at
      assert_equal pack.end_date.to_time + 1.day - 1.minute, last_sale.reload.ends_at
    end
  end
end
