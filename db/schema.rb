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

ActiveRecord::Schema[7.2].define(version: 2026_02_08_053724) do
  create_table "bookmarks", charset: "utf8mb4", collation: "utf8mb4_general_ci", force: :cascade do |t|
    t.integer "user_id", null: false
    t.string "title", null: false
    t.string "url", null: false
    t.boolean "deleted", default: false, null: false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "calendars", charset: "utf8mb4", collation: "utf8mb4_general_ci", force: :cascade do |t|
    t.integer "user_id", null: false
    t.string "title"
    t.boolean "deleted", default: false, null: false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "feeds", charset: "utf8mb4", collation: "utf8mb4_general_ci", force: :cascade do |t|
    t.integer "user_id", null: false
    t.string "title", null: false
    t.string "feed_url", null: false
    t.boolean "deleted", default: false, null: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer "display_count", default: 5, null: false
  end

  create_table "portal_layouts", charset: "utf8mb4", collation: "utf8mb4_general_ci", force: :cascade do |t|
    t.integer "user_id", null: false
    t.integer "column_no", default: 0, null: false
    t.integer "display_order", default: 0, null: false
    t.string "gadget_id", null: false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "portals", charset: "utf8mb4", collation: "utf8mb4_general_ci", force: :cascade do |t|
    t.integer "user_id", null: false
    t.string "name", null: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean "deleted", default: false, null: false
  end

  create_table "preferences", charset: "utf8mb4", collation: "utf8mb4_general_ci", force: :cascade do |t|
    t.integer "user_id", null: false
    t.string "theme"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean "use_todo", default: false, null: false
    t.integer "default_priority"
  end

  create_table "todos", charset: "utf8mb4", collation: "utf8mb4_general_ci", force: :cascade do |t|
    t.integer "user_id", null: false
    t.string "title", null: false
    t.integer "priority", null: false
    t.boolean "deleted", default: false, null: false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "tweets", charset: "utf8mb4", collation: "utf8mb4_general_ci", force: :cascade do |t|
    t.integer "user_id", null: false
    t.string "tweet_id", null: false
    t.string "twitter_user_id", null: false
    t.string "twitter_user_name", null: false
    t.boolean "deleted", default: false, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.text "content", size: :medium
    t.integer "retweet_count", default: 0, null: false
  end

  create_table "users", charset: "utf8mb4", collation: "utf8mb4_general_ci", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer "sign_in_count", default: 0
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string "current_sign_in_ip"
    t.string "last_sign_in_ip"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean "admin", default: false, null: false
    t.string "provider"
    t.string "uid"
    t.string "token"
    t.string "name"
    t.string "otp_secret", null: false
    t.integer "consumed_timestep"
    t.boolean "otp_required_for_login", default: false, null: false
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["name"], name: "index_users_on_name", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end
end
