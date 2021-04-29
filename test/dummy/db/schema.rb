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

ActiveRecord::Schema.define(version: 2021_04_29_051508) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"
  enable_extension "unaccent"

  create_folio_unaccent

  create_table "auctify_bidder_registrations", force: :cascade do |t|
    t.string "bidder_type", null: false
    t.bigint "bidder_id", null: false
    t.bigint "auction_id", null: false
    t.string "aasm_state", default: "pending", null: false
    t.datetime "handled_at"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["aasm_state"], name: "index_auctify_bidder_registrations_on_aasm_state"
    t.index ["auction_id"], name: "index_auctify_bidder_registrations_on_auction_id"
    t.index ["bidder_type", "bidder_id"], name: "index_auctify_bidder_registrations_on_bidder"
  end

  create_table "auctify_bids", force: :cascade do |t|
    t.bigint "registration_id", null: false
    t.decimal "price", precision: 12, scale: 2, null: false
    t.decimal "max_price", precision: 12, scale: 2
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["registration_id"], name: "index_auctify_bids_on_registration_id"
  end

  create_table "auctify_sales", force: :cascade do |t|
    t.string "seller_type"
    t.integer "seller_id"
    t.string "buyer_type"
    t.bigint "buyer_id"
    t.bigint "item_id", null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.string "type", default: "Auctify::Sale::Base"
    t.string "aasm_state", default: "offered", null: false
    t.decimal "offered_price", precision: 12, scale: 2
    t.decimal "current_price", precision: 12, scale: 2
    t.decimal "sold_price", precision: 12, scale: 2
    t.jsonb "bid_steps_ladder"
    t.decimal "reserve_price"
    t.bigint "pack_id"
    t.datetime "ends_at"
    t.integer "position"
    t.string "number"
    t.datetime "currently_ends_at"
    t.boolean "published", default: false
    t.boolean "featured", default: false
    t.index ["buyer_type", "buyer_id"], name: "index_auctify_sales_on_buyer_type_and_buyer_id"
    t.index ["featured"], name: "index_auctify_sales_on_featured"
    t.index ["pack_id"], name: "index_auctify_sales_on_pack_id"
    t.index ["position"], name: "index_auctify_sales_on_position"
    t.index ["published"], name: "index_auctify_sales_on_published"
    t.index ["seller_type", "seller_id"], name: "index_auctify_sales_on_seller_type_and_seller_id"
  end

  create_table "auctify_sales_packs", force: :cascade do |t|
    t.string "title"
    t.text "description"
    t.integer "position", default: 0
    t.string "slug"
    t.string "place"
    t.boolean "published", default: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.integer "sales_count", default: 0
    t.date "start_date"
    t.date "end_date"
    t.integer "sales_interval", default: 3
    t.integer "sales_beginning_hour", default: 20
    t.integer "sales_beginning_minutes", default: 0
    t.index ["position"], name: "index_auctify_sales_packs_on_position"
    t.index ["published"], name: "index_auctify_sales_packs_on_published"
    t.index ["slug"], name: "index_auctify_sales_packs_on_slug"
  end

  create_table "audits", force: :cascade do |t|
    t.bigint "auditable_id"
    t.string "auditable_type"
    t.bigint "associated_id"
    t.string "associated_type"
    t.bigint "user_id"
    t.string "user_type"
    t.string "username"
    t.string "action"
    t.jsonb "audited_changes"
    t.integer "version", default: 0
    t.string "comment"
    t.string "remote_address"
    t.string "request_uuid"
    t.datetime "created_at"
    t.integer "placement_version"
    t.index ["associated_type", "associated_id"], name: "associated_index"
    t.index ["auditable_type", "auditable_id", "version"], name: "auditable_index"
    t.index ["created_at"], name: "index_audits_on_created_at"
    t.index ["placement_version"], name: "index_audits_on_placement_version"
    t.index ["request_uuid"], name: "index_audits_on_request_uuid"
    t.index ["user_id", "user_type"], name: "user_index"
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

  create_table "folio_accounts", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer "sign_in_count", default: 0, null: false
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string "current_sign_in_ip"
    t.string "last_sign_in_ip"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "first_name"
    t.string "last_name"
    t.string "role"
    t.boolean "is_active", default: true
    t.string "invitation_token"
    t.datetime "invitation_created_at"
    t.datetime "invitation_sent_at"
    t.datetime "invitation_accepted_at"
    t.integer "invitation_limit"
    t.string "invited_by_type"
    t.bigint "invited_by_id"
    t.integer "invitations_count", default: 0
    t.index ["email"], name: "index_folio_accounts_on_email", unique: true
    t.index ["invitation_token"], name: "index_folio_accounts_on_invitation_token", unique: true
    t.index ["invitations_count"], name: "index_folio_accounts_on_invitations_count"
    t.index ["invited_by_id"], name: "index_folio_accounts_on_invited_by_id"
    t.index ["invited_by_type", "invited_by_id"], name: "index_folio_accounts_on_invited_by_type_and_invited_by_id"
    t.index ["reset_password_token"], name: "index_folio_accounts_on_reset_password_token", unique: true
  end

  create_table "folio_addresses", force: :cascade do |t|
    t.string "name"
    t.string "company_name"
    t.string "address_line_1"
    t.string "address_line_2"
    t.string "zip"
    t.string "city"
    t.string "country_code"
    t.string "state"
    t.string "identification_number"
    t.string "vat_identification_number"
    t.string "phone"
    t.string "email"
    t.string "type"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["type"], name: "index_folio_addresses_on_type"
  end

  create_table "folio_atoms", force: :cascade do |t|
    t.string "type"
    t.integer "position"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "placement_type"
    t.bigint "placement_id"
    t.string "locale"
    t.jsonb "data", default: {}
    t.jsonb "associations", default: {}
    t.text "data_for_search"
    t.index ["placement_type", "placement_id"], name: "index_folio_atoms_on_placement_type_and_placement_id"
  end

  create_table "folio_content_templates", force: :cascade do |t|
    t.text "content"
    t.integer "position"
    t.string "type"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["position"], name: "index_folio_content_templates_on_position"
    t.index ["type"], name: "index_folio_content_templates_on_type"
  end

  create_table "folio_email_templates", force: :cascade do |t|
    t.string "title"
    t.string "slug"
    t.string "mailer"
    t.string "action"
    t.string "subject_en"
    t.text "body_html_en"
    t.text "body_text_en"
    t.jsonb "required_keywords"
    t.jsonb "optional_keywords"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["slug"], name: "index_folio_email_templates_on_slug"
  end

  create_table "folio_file_placements", force: :cascade do |t|
    t.string "placement_type"
    t.bigint "placement_id"
    t.bigint "file_id"
    t.integer "position"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "type"
    t.text "title"
    t.string "alt"
    t.string "placement_title"
    t.string "placement_title_type"
    t.index ["file_id"], name: "index_folio_file_placements_on_file_id"
    t.index ["placement_title"], name: "index_folio_file_placements_on_placement_title"
    t.index ["placement_title_type"], name: "index_folio_file_placements_on_placement_title_type"
    t.index ["placement_type", "placement_id"], name: "index_folio_file_placements_on_placement_type_and_placement_id"
    t.index ["type"], name: "index_folio_file_placements_on_type"
  end

  create_table "folio_files", force: :cascade do |t|
    t.string "file_uid"
    t.string "file_name"
    t.string "type"
    t.text "thumbnail_sizes", default: "--- {}\n"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "file_width"
    t.integer "file_height"
    t.bigint "file_size"
    t.string "mime_type", limit: 255
    t.json "additional_data"
    t.json "file_metadata"
    t.string "hash_id"
    t.string "author"
    t.text "description"
    t.integer "file_placements_size"
    t.string "file_name_for_search"
    t.boolean "sensitive_content", default: false
    t.index "to_tsvector('simple'::regconfig, folio_unaccent(COALESCE((author)::text, ''::text)))", name: "index_folio_files_on_by_author", using: :gin
    t.index "to_tsvector('simple'::regconfig, folio_unaccent(COALESCE((file_name_for_search)::text, ''::text)))", name: "index_folio_files_on_by_file_name_for_search", using: :gin
    t.index ["created_at"], name: "index_folio_files_on_created_at"
    t.index ["file_name"], name: "index_folio_files_on_file_name"
    t.index ["hash_id"], name: "index_folio_files_on_hash_id"
    t.index ["type"], name: "index_folio_files_on_type"
    t.index ["updated_at"], name: "index_folio_files_on_updated_at"
  end

  create_table "folio_leads", force: :cascade do |t|
    t.string "email"
    t.string "phone"
    t.text "note"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "name"
    t.string "url"
    t.json "additional_data"
    t.string "aasm_state", default: "submitted"
  end

  create_table "folio_menu_items", force: :cascade do |t|
    t.bigint "menu_id"
    t.string "ancestry"
    t.string "title"
    t.string "rails_path"
    t.integer "position"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "target_type"
    t.bigint "target_id"
    t.string "url"
    t.boolean "open_in_new"
    t.string "style"
    t.integer "folio_page_id"
    t.index ["ancestry"], name: "index_folio_menu_items_on_ancestry"
    t.index ["menu_id"], name: "index_folio_menu_items_on_menu_id"
    t.index ["target_type", "target_id"], name: "index_folio_menu_items_on_target_type_and_target_id"
  end

  create_table "folio_menus", force: :cascade do |t|
    t.string "type"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "locale"
    t.string "title"
    t.index ["type"], name: "index_folio_menus_on_type"
  end

  create_table "folio_newsletter_subscriptions", force: :cascade do |t|
    t.string "email"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "subscribable_type"
    t.bigint "subscribable_id"
    t.boolean "active", default: true
    t.string "tags"
    t.text "merge_vars"
    t.index ["subscribable_type", "subscribable_id"], name: "index_folio_newsletter_subscriptions_on_subscribable"
  end

  create_table "folio_omniauth_authentications", force: :cascade do |t|
    t.bigint "folio_user_id"
    t.string "uid"
    t.string "provider"
    t.string "email"
    t.string "nickname"
    t.string "access_token"
    t.json "raw_info"
    t.string "conflict_token"
    t.integer "conflict_user_id"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["folio_user_id"], name: "index_folio_omniauth_authentications_on_folio_user_id"
  end

  create_table "folio_pages", force: :cascade do |t|
    t.string "title"
    t.string "slug"
    t.text "perex"
    t.string "meta_title", limit: 512
    t.text "meta_description"
    t.string "ancestry"
    t.string "type"
    t.boolean "featured"
    t.integer "position"
    t.boolean "published"
    t.datetime "published_at"
    t.integer "original_id"
    t.string "locale", limit: 6
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["ancestry"], name: "index_folio_pages_on_ancestry"
    t.index ["featured"], name: "index_folio_pages_on_featured"
    t.index ["locale"], name: "index_folio_pages_on_locale"
    t.index ["original_id"], name: "index_folio_pages_on_original_id"
    t.index ["position"], name: "index_folio_pages_on_position"
    t.index ["published"], name: "index_folio_pages_on_published"
    t.index ["published_at"], name: "index_folio_pages_on_published_at"
    t.index ["slug"], name: "index_folio_pages_on_slug"
    t.index ["type"], name: "index_folio_pages_on_type"
  end

  create_table "folio_private_attachments", force: :cascade do |t|
    t.string "attachmentable_type"
    t.bigint "attachmentable_id"
    t.string "type"
    t.string "file_uid"
    t.string "file_name"
    t.text "title"
    t.string "alt"
    t.text "thumbnail_sizes"
    t.integer "position"
    t.integer "file_width"
    t.integer "file_height"
    t.bigint "file_size"
    t.string "mime_type", limit: 255
    t.json "additional_data"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "hash_id"
    t.index ["attachmentable_type", "attachmentable_id"], name: "index_folio_private_attachments_on_attachmentable"
    t.index ["type"], name: "index_folio_private_attachments_on_type"
  end

  create_table "folio_session_attachments", force: :cascade do |t|
    t.string "hash_id"
    t.string "file_uid"
    t.string "file_name"
    t.bigint "file_size"
    t.string "file_mime_type"
    t.string "type"
    t.string "web_session_id"
    t.string "placement_type"
    t.bigint "placement_id"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.integer "file_width"
    t.integer "file_height"
    t.index ["hash_id"], name: "index_folio_session_attachments_on_hash_id"
    t.index ["placement_type", "placement_id"], name: "index_folio_session_attachments_on_placement"
    t.index ["type"], name: "index_folio_session_attachments_on_type"
    t.index ["web_session_id"], name: "index_folio_session_attachments_on_web_session_id"
  end

  create_table "folio_sites", force: :cascade do |t|
    t.string "title"
    t.string "domain"
    t.string "email"
    t.string "phone"
    t.string "locale"
    t.string "locales", default: [], array: true
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "google_analytics_tracking_code"
    t.string "facebook_pixel_code"
    t.json "social_links"
    t.text "address"
    t.text "description"
    t.string "system_email"
    t.string "system_email_copy"
    t.string "email_from"
    t.index ["domain"], name: "index_folio_sites_on_domain"
  end

  create_table "folio_users", force: :cascade do |t|
    t.string "email"
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer "sign_in_count", default: 0, null: false
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.inet "current_sign_in_ip"
    t.inet "last_sign_in_ip"
    t.string "confirmation_token"
    t.datetime "confirmed_at"
    t.datetime "confirmation_sent_at"
    t.string "unconfirmed_email"
    t.string "first_name"
    t.string "last_name"
    t.text "admin_note"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.string "invitation_token"
    t.datetime "invitation_created_at"
    t.datetime "invitation_sent_at"
    t.datetime "invitation_accepted_at"
    t.integer "invitation_limit"
    t.string "invited_by_type"
    t.bigint "invited_by_id"
    t.integer "invitations_count", default: 0
    t.string "nickname"
    t.boolean "use_secondary_address", default: false
    t.bigint "primary_address_id"
    t.bigint "secondary_address_id"
    t.boolean "subscribed_to_newsletter", default: false
    t.index ["confirmation_token"], name: "index_folio_users_on_confirmation_token", unique: true
    t.index ["email"], name: "index_folio_users_on_email"
    t.index ["invitation_token"], name: "index_folio_users_on_invitation_token", unique: true
    t.index ["invited_by_id"], name: "index_folio_users_on_invited_by_id"
    t.index ["invited_by_type", "invited_by_id"], name: "index_folio_users_on_invited_by_type_and_invited_by_id"
    t.index ["primary_address_id"], name: "index_folio_users_on_primary_address_id"
    t.index ["reset_password_token"], name: "index_folio_users_on_reset_password_token", unique: true
    t.index ["secondary_address_id"], name: "index_folio_users_on_secondary_address_id"
  end

  create_table "friendly_id_slugs", force: :cascade do |t|
    t.string "slug", null: false
    t.integer "sluggable_id", null: false
    t.string "sluggable_type", limit: 50
    t.string "scope"
    t.datetime "created_at"
    t.index ["slug", "sluggable_type", "scope"], name: "index_friendly_id_slugs_on_slug_and_sluggable_type_and_scope", unique: true
    t.index ["slug", "sluggable_type"], name: "index_friendly_id_slugs_on_slug_and_sluggable_type"
    t.index ["sluggable_id"], name: "index_friendly_id_slugs_on_sluggable_id"
    t.index ["sluggable_type"], name: "index_friendly_id_slugs_on_sluggable_type"
  end

  create_table "pg_search_documents", force: :cascade do |t|
    t.text "content"
    t.string "searchable_type"
    t.bigint "searchable_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index "to_tsvector('simple'::regconfig, folio_unaccent(COALESCE(content, ''::text)))", name: "index_pg_search_documents_on_public_search", using: :gin
    t.index ["searchable_type", "searchable_id"], name: "index_pg_search_documents_on_searchable_type_and_searchable_id"
  end

  create_table "taggings", id: :serial, force: :cascade do |t|
    t.integer "tag_id"
    t.string "taggable_type"
    t.integer "taggable_id"
    t.string "tagger_type"
    t.integer "tagger_id"
    t.string "context", limit: 128
    t.datetime "created_at"
    t.index ["context"], name: "index_taggings_on_context"
    t.index ["tag_id", "taggable_id", "taggable_type", "context", "tagger_id", "tagger_type"], name: "taggings_idx", unique: true
    t.index ["tag_id"], name: "index_taggings_on_tag_id"
    t.index ["taggable_id", "taggable_type", "context"], name: "index_taggings_on_taggable_id_and_taggable_type_and_context"
    t.index ["taggable_id", "taggable_type", "tagger_id", "context"], name: "taggings_idy"
    t.index ["taggable_id"], name: "index_taggings_on_taggable_id"
    t.index ["taggable_type"], name: "index_taggings_on_taggable_type"
    t.index ["tagger_id", "tagger_type"], name: "index_taggings_on_tagger_id_and_tagger_type"
    t.index ["tagger_id"], name: "index_taggings_on_tagger_id"
  end

  create_table "tags", id: :serial, force: :cascade do |t|
    t.string "name"
    t.integer "taggings_count", default: 0
    t.index "to_tsvector('simple'::regconfig, folio_unaccent(COALESCE((name)::text, ''::text)))", name: "index_tags_on_by_query", using: :gin
    t.index ["name"], name: "index_tags_on_name", unique: true
  end

  create_table "things", force: :cascade do |t|
    t.string "name"
    t.integer "owner_id"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.integer "sales_count", default: 0
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
