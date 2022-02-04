# frozen_string_literal: true

require "test_helper"

module Auctify
  class SalesPackTest < ActiveSupport::TestCase
    test "dates_to_label" do
      # with default format
      pack = Auctify::SalesPack.new(start_date: Date.new(2021, 1, 1), end_date: Date.new(2021, 1, 3))
      assert_equal("1. – 3. 1. 2021", pack.dates_to_label)

      pack = Auctify::SalesPack.new(start_date: Date.new(2021, 1, 29), end_date: Date.new(2021, 2, 1))
      assert_equal("29. 1. – 1. 2. 2021", pack.dates_to_label)

      pack = Auctify::SalesPack.new(start_date: Date.new(2020, 12, 30), end_date: Date.new(2021, 1, 2))
      assert_equal("30. 12. 2020 – 2. 1. 2021", pack.dates_to_label)
    end

    test "forbid deleting if there are any sales" do
      pack = auctify_sales_packs(:things_from_eden)
      sales = pack.sales.reload
      assert_equal 2, sales.size

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

    test "#shift_sales_by_minutes moves all sales in transaction" do
      original_start_date = Date.tomorrow
      shift_in_minutes = 7 * 24 * 60 # one week


      pack = Auctify::SalesPack.create!(title: "Ready to launch",
                                        start_date: original_start_date,
                                        end_date: original_start_date + 7.days)
      firts_sale_ends_at = pack.start_date.to_time + 1.hour
      last_sale_ends_at = pack.end_date.to_time + 1.day - 1.minute

      firts_sale = Auctify::Sale::Auction.create!(seller: users(:eve),
                                                  item: things(:apple),
                                                  offered_price: 100.0,
                                                  pack: pack,
                                                  ends_at: firts_sale_ends_at)

      last_sale = Auctify::Sale::Auction.create!(seller: users(:adam),
                                                 item: things(:innocence),
                                                 offered_price: 100.0,
                                                 pack: pack,
                                                 ends_at: last_sale_ends_at)

      assert_equal 2, pack.sales.reload.size

      assert_raises(ActiveRecord::RecordInvalid) { pack.shift_sales_by_minutes!(shift_in_minutes) }

      assert_includes pack.errors[:sales], "Položka '#{last_sale.slug}' má čas konce (#{I18n.l(last_sale.ends_at + shift_in_minutes.minutes)}) mimo rámec aukce"
      assert_equal firts_sale_ends_at, firts_sale.reload.ends_at # Rollback should happened, so no change here too
      assert_equal last_sale_ends_at, last_sale.reload.ends_at

      pack.errors.clear
      pack.sales.reload
      pack.end_date = (last_sale_ends_at + shift_in_minutes.minutes).to_date

      pack.shift_sales_by_minutes!(shift_in_minutes)

      assert_equal firts_sale_ends_at + shift_in_minutes.minutes, firts_sale.reload.ends_at
      assert_equal last_sale_ends_at + shift_in_minutes.minutes, last_sale.reload.ends_at
    end

    test "validates ends_at times of all sales" do
      original_start_date = Date.tomorrow
      pack = Auctify::SalesPack.create!(title: "Ready to launch",
                                        start_date: original_start_date,
                                        end_date: original_start_date + 7.days)
      assert pack.valid? # no sales

      pack = auctify_sales_packs(:things_from_eden)
      sales = pack.sales.reload
      assert_equal 2, sales.size

      assert pack.valid?, pack.errors.full_messages

      sale = sales.last
      sale.ends_at = pack.end_date.to_time + 1.day
      sale.save(validation: false)
      pack.sales.reload

      assert pack.reload.valid?

      sales.last.update!(ends_at: pack.end_date.to_time + 1.day + 1.minute)
      pack.sales.reload

      assert_not pack.reload.valid?
      assert_includes pack.errors[:sales], "Položka 'adam_innoncence' má čas konce (Čt 01. únor 0001 23:03 +0000) mimo rámec aukce"
    end
  end
end
