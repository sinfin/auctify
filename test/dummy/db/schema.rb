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

ActiveRecord::Schema.define(version: 2021_02_17_101246) do

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
    t.index ["buyer_type", "buyer_id"], name: "index_auctify_sales_on_buyer_type_and_buyer_id"
    t.index ["item_type", "item_id"], name: "index_auctify_sales_on_item_type_and_item_id"
    t.index ["seller_type", "seller_id"], name: "index_auctify_sales_on_seller_type_and_seller_id"
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

  add_foreign_key "things", "users", column: "owner_id"
end
