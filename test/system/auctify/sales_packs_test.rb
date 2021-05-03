# frozen_string_literal: true

require "application_system_test_case"

module Auctify
  class SalesPacksTest < ApplicationSystemTestCase
    setup do
      @sales_pack = auctify_sales_packs(:things_from_eden)
    end

    test "visiting the index" do
      visit sales_packs_url
      assert_selector "h1", text: "Sales Packs"
    end

    test "creating a Sales pack" do
      visit sales_packs_url
      click_on "New Sales Pack"

      fill_in "Description", with: @sales_pack.description
      fill_in "Place", with: @sales_pack.place
      fill_in "Position", with: @sales_pack.position
      check "Published" if @sales_pack.published
      fill_in "Slug", with: @sales_pack.slug
      fill_in "Start date", with: @sales_pack.start_date
      fill_in "End date", with: @sales_pack.end_date
      fill_in "Title", with: @sales_pack.title
      click_on "Create Sales pack"

      assert_text "Sales pack was successfully created"
      click_on "Back"
    end

    test "updating a Sales pack" do
      visit sales_packs_url
      click_on "Edit", match: :first

      fill_in "Description", with: @sales_pack.description
      fill_in "Place", with: @sales_pack.place
      fill_in "Position", with: @sales_pack.position
      check "Published" if @sales_pack.published
      fill_in "Slug", with: @sales_pack.slug
      fill_in "Start date", with: @sales_pack.start_date
      fill_in "End date", with: @sales_pack.end_date
      fill_in "Title", with: @sales_pack.title
      click_on "Update Sales pack"

      assert_text "Sales pack was successfully updated"
      click_on "Back"
    end

    test "destroying a Sales pack" do
      visit sales_packs_url
      page.accept_confirm do
        click_on "Destroy", match: :first
      end

      assert_text "Sales pack was successfully destroyed"
    end
  end
end
