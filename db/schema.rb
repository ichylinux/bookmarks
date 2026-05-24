# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2026_05_24_000004) do
  create_table "bookmarks", charset: "utf8mb4", collation: "utf8mb4_general_ci", force: :cascade do |t|
    t.datetime "created_at"
    t.boolean "deleted", default: false, null: false
    t.integer "parent_id"
    t.string "title", null: false
    t.datetime "updated_at"
    t.string "url"
    t.bigint "user_id", null: false
    t.index ["user_id"], name: "fk_rails_c1ff6fa4ac"
  end

  create_table "feeds", charset: "utf8mb4", collation: "utf8mb4_general_ci", force: :cascade do |t|
    t.datetime "created_at"
    t.boolean "deleted", default: false, null: false
    t.integer "display_count", default: 5, null: false
    t.string "feed_url", null: false
    t.string "title", null: false
    t.datetime "updated_at"
    t.bigint "user_id", null: false
    t.index ["user_id"], name: "fk_rails_36f9216dc2"
  end

  create_table "mastodon_accounts", charset: "utf8mb4", collation: "utf8mb4_general_ci", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.boolean "deleted", default: false, null: false
    t.integer "display_count", default: 5, null: false
    t.string "instance", null: false
    t.string "profile_url", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.string "username", null: false
    t.index ["user_id"], name: "index_mastodon_accounts_on_user_id"
  end

  create_table "notes", charset: "utf8mb4", collation: "utf8mb4_general_ci", force: :cascade do |t|
    t.text "body", null: false
    t.datetime "created_at", null: false
    t.boolean "deleted", default: false, null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["user_id", "created_at"], name: "index_notes_on_user_id_and_created_at"
  end

  create_table "oauth_identities", charset: "utf8mb4", collation: "utf8mb4_general_ci", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "provider", null: false
    t.string "uid", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["user_id", "provider"], name: "index_oauth_identities_on_user_id_and_provider", unique: true
    t.index ["user_id"], name: "index_oauth_identities_on_user_id"
  end

  create_table "portal_layouts", charset: "utf8mb4", collation: "utf8mb4_general_ci", force: :cascade do |t|
    t.integer "column_no", default: 0, null: false
    t.datetime "created_at"
    t.integer "display_order", default: 0, null: false
    t.string "gadget_id", null: false
    t.datetime "updated_at"
    t.bigint "user_id", null: false
    t.index ["user_id"], name: "fk_rails_50b0a233d8"
  end

  create_table "portals", charset: "utf8mb4", collation: "utf8mb4_general_ci", force: :cascade do |t|
    t.datetime "created_at"
    t.boolean "deleted", default: false, null: false
    t.string "name", null: false
    t.datetime "updated_at"
    t.bigint "user_id", null: false
    t.index ["user_id"], name: "fk_rails_dbbca7988d"
  end

  create_table "preferences", charset: "utf8mb4", collation: "utf8mb4_general_ci", force: :cascade do |t|
    t.datetime "created_at"
    t.integer "default_priority"
    t.string "font_size"
    t.boolean "font_size_notice_pending", default: false, null: false
    t.string "locale"
    t.boolean "open_links_in_new_tab", default: false, null: false
    t.integer "portal_column_count", default: 3, null: false
    t.json "portal_column_widths"
    t.boolean "show_column_nav_buttons", default: false, null: false
    t.boolean "show_icons", default: true, null: false
    t.string "theme"
    t.datetime "updated_at"
    t.boolean "use_calendar", default: false, null: false
    t.boolean "use_note", default: false, null: false
    t.boolean "use_todo", default: false, null: false
    t.bigint "user_id", null: false
    t.index ["user_id"], name: "fk_rails_87f1c9c7bd"
  end

  create_table "todos", charset: "utf8mb4", collation: "utf8mb4_general_ci", force: :cascade do |t|
    t.datetime "created_at"
    t.boolean "deleted", default: false, null: false
    t.integer "priority", null: false
    t.string "title", null: false
    t.datetime "updated_at"
    t.bigint "user_id", null: false
    t.index ["user_id"], name: "fk_rails_d94154aa95"
  end

  create_table "users", charset: "utf8mb4", collation: "utf8mb4_general_ci", force: :cascade do |t|
    t.boolean "admin", default: false, null: false
    t.integer "consumed_timestep"
    t.datetime "created_at"
    t.datetime "current_sign_in_at"
    t.string "current_sign_in_ip"
    t.boolean "deleted", default: false, null: false
    t.datetime "deleted_at"
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.datetime "last_sign_in_at"
    t.string "last_sign_in_ip"
    t.string "oauth2_refresh_token"
    t.string "oauth2_token"
    t.datetime "oauth2_token_expires_at"
    t.boolean "otp_required_for_login", default: false, null: false
    t.string "otp_secret", null: false
    t.boolean "password_auth_enabled", default: false, null: false
    t.string "provider"
    t.datetime "remember_created_at"
    t.datetime "reset_password_sent_at"
    t.string "reset_password_token"
    t.integer "sign_in_count", default: 0
    t.string "uid"
    t.datetime "updated_at"
    t.datetime "x_accounts_last_refreshed_at"
    t.string "x_user_name"
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
    t.index ["uid"], name: "index_users_on_uid", unique: true
  end

  create_table "visited_links", charset: "utf8mb4", collation: "utf8mb4_general_ci", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "url", limit: 2083, null: false
    t.bigint "user_id", null: false
    t.datetime "visited_at", null: false
    t.index ["user_id", "url"], name: "index_visited_links_on_user_id_and_url", unique: true, length: { url: 766 }
  end

  create_table "x_accounts", charset: "utf8mb4", collation: "utf8mb4_general_ci", force: :cascade do |t|
    t.string "avatar_url"
    t.datetime "created_at", null: false
    t.boolean "deleted", default: false, null: false
    t.integer "display_count", default: 5, null: false
    t.string "display_name", default: "", null: false
    t.boolean "manually_added", default: false, null: false
    t.boolean "protected", default: false, null: false
    t.boolean "protected_acknowledged", default: false, null: false
    t.boolean "selected", default: false, null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.string "username", null: false
    t.string "x_user_id", null: false
    t.index ["user_id", "x_user_id"], name: "index_x_accounts_on_user_id_and_x_user_id", unique: true
    t.index ["user_id"], name: "index_x_accounts_on_user_id"
  end

  create_table "x_api_calls", charset: "utf8mb4", collation: "utf8mb4_general_ci", force: :cascade do |t|
    t.datetime "called_at", null: false
    t.string "endpoint", null: false
    t.string "error_code", limit: 32
    t.integer "rate_limit_remaining"
    t.boolean "success", null: false
    t.bigint "user_id", null: false
    t.index ["user_id", "called_at"], name: "index_x_api_calls_on_user_id_and_called_at"
  end

  add_foreign_key "bookmarks", "users", on_delete: :cascade
  add_foreign_key "feeds", "users", on_delete: :cascade
  add_foreign_key "mastodon_accounts", "users", on_delete: :cascade
  add_foreign_key "notes", "users", on_delete: :cascade
  add_foreign_key "oauth_identities", "users", on_delete: :cascade
  add_foreign_key "portal_layouts", "users", on_delete: :cascade
  add_foreign_key "portals", "users", on_delete: :cascade
  add_foreign_key "preferences", "users", on_delete: :cascade
  add_foreign_key "todos", "users", on_delete: :cascade
  add_foreign_key "visited_links", "users", on_delete: :cascade
  add_foreign_key "x_accounts", "users", on_delete: :cascade
  add_foreign_key "x_api_calls", "users", on_delete: :cascade
end
