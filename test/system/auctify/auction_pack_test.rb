# frozen_string_literal: true

require "application_system_test_case"

module Auctify
  class AuctionPackTest < ApplicationSystemTestCase
    setup do
    end

    test "preparing auction pack" do
      create_auction_pack
      add_auctions_to_it
    end

    def create_auction_pack
      visit auctify_auction_packs_url
      assert_selector "h1", text: "Auction Packs"

      click_on "New"

      #  id          :bigint(8)        not null, primary key
      #  date        :string
      #  description :text
      #  items_count :integer          default(0)
      #  position    :integer
      #  published   :boolean          default(FALSE)
      #  slug        :string
      #  title       :string
      #  created_at  :datetime         not null
      #  updated_at  :datetime         not null
      decription = "We have 8 wolfs, some of them are from Winterfell"
      time_frame = "1.1.2021 - 31.12.2021"

      fill_in "Title", with: "Wolf Pack"
      fill_in "Slug", with: "wolf-pack"
      fill_in "Description", with: decription
      fill_in "Date", with: time_frame
      fill_in "Position", with: "1"
      check "Published"

      click_on "Submit"

      assert_text "Auction pack was successfully created"
      assert_selector "h1", text: "Wolf Pack"
      assert_text decription
      assert_text time_frame

      assert_text "Add auctioned item"
    end

    def add_auctions_to_it
      click_on "Add auctioned item"
    end
  end
end
