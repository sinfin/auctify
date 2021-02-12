require "application_system_test_case"

class ThingsTest < ApplicationSystemTestCase
  setup do
    @thing = things(:one)
  end

  test "visiting the index" do
    visit things_url
    assert_selector "h1", text: "Things"
  end

  test "creating a Thing" do
    visit things_url
    click_on "New Thing"

    fill_in "Name", with: @thing.name
    fill_in "Owner", with: @thing.owner_id
    click_on "Create Thing"

    assert_text "Thing was successfully created"
    click_on "Back"
  end

  test "updating a Thing" do
    visit things_url
    click_on "Edit", match: :first

    fill_in "Name", with: @thing.name
    fill_in "Owner", with: @thing.owner_id
    click_on "Update Thing"

    assert_text "Thing was successfully updated"
    click_on "Back"
  end

  test "destroying a Thing" do
    visit things_url
    page.accept_confirm do
      click_on "Destroy", match: :first
    end

    assert_text "Thing was successfully destroyed"
  end
end
