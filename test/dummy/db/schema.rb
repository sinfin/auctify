# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `rails
# db:schema:load`. When creating a new database, `rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 2021_04_19_083321) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "auctify_auction_packs", force: :cascade do |t|
    t.string "title"
    t.text "description"
    t.integer "position", default: 0
    t.string "slug"
    t.string "time_frame"
    t.boolean "published", default: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
  end

  create_table "auctify_bidder_registrations", force: :cascade do |t|
    t.string "bidder_type", null: false
    t.integer "bidder_id", null: false
    t.integer "auction_id", null: false
    t.string "aasm_state", default: "pending", null: false
    t.datetime "handled_at"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["aasm_state"], name: "index_auctify_bidder_registrations_on_aasm_state"
    t.index ["auction_id"], name: "index_auctify_bidder_registrations_on_auction_id"
    t.index ["bidder_type", "bidder_id"], name: "index_auctify_bidder_registrations_on_bidder"
  end

  create_table "auctify_bids", force: :cascade do |t|
    t.integer "registration_id", null: false
    t.decimal "price", precision: 12, scale: 2, null: false
    t.decimal "max_price", precision: 12, scale: 2
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["registration_id"], name: "index_auctify_bids_on_registration_id"
  end

  create_table "auctify_sales", force: :cascade do |t|
    t.string "seller_type", null: false
    t.integer "seller_id", null: false
    t.string "buyer_type"
    t.integer "buyer_id"
    t.string "item_type", null: false
    t.integer "item_id", null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.string "type", default: "Auctify::Sale::Base"
    t.string "aasm_state", default: "offered", null: false
    t.decimal "selling_price"
    t.datetime "published_at"
    t.decimal "offered_price"
    t.decimal "current_price"
    t.decimal "sold_price"
    t.json "bid_steps_ladder"
    t.decimal "reserve_price"
    t.bigint "pack_id"
    t.datetime "ends_at"
    t.integer "position"
    t.index ["buyer_type", "buyer_id"], name: "index_auctify_sales_on_buyer_type_and_buyer_id"
    t.index ["item_type", "item_id"], name: "index_auctify_sales_on_item_type_and_item_id"
    t.index ["pack_id"], name: "index_auctify_sales_on_pack_id"
    t.index ["position"], name: "index_auctify_sales_on_position"
    t.index ["published_at"], name: "index_auctify_sales_on_published_at"
    t.index ["seller_type", "seller_id"], name: "index_auctify_sales_on_seller_type_and_seller_id"
  end

  create_table "auctify_sales_packs", force: :cascade do |t|
    t.string "title"
    t.text "description"
    t.integer "position", default: 0
    t.string "slug"
    t.string "time_frame"
    t.string "place"
    t.boolean "published", default: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.integer "sales_count", default: 0
    t.index ["position"], name: "index_auctify_sales_packs_on_position"
    t.index ["published"], name: "index_auctify_sales_packs_on_published"
    t.index ["slug"], name: "index_auctify_sales_packs_on_slug"
  end

  create_table "clean_things", force: :cascade do |t|
    t.string "name"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
  end

  create_table "clean_users", force: :cascade do |t|
    t.string "name"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
  end

  create_table "things", force: :cascade do |t|
    t.string "name"
    t.integer "owner_id", null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["owner_id"], name: "index_things_on_owner_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "name"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
  end

  add_foreign_key "auctify_bidder_registrations", "auctify_sales", column: "auction_id"
  add_foreign_key "auctify_bids", "auctify_bidder_registrations", column: "registration_id"
  add_foreign_key "things", "users", column: "owner_id"
end
