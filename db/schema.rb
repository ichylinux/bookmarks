# encoding: UTF-8
# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 20150704071642) do

  create_table "bookmarks", force: :cascade do |t|
    t.integer  "user_id",    limit: 4,                   null: false
    t.string   "title",      limit: 255,                 null: false
    t.string   "url",        limit: 255,                 null: false
    t.boolean  "deleted",                default: false, null: false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "calendars", force: :cascade do |t|
    t.integer  "user_id",      limit: 4,                   null: false
    t.string   "title",        limit: 255
    t.boolean  "deleted",                  default: false, null: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "show_weather",             default: false, null: false
  end

  create_table "feeds", force: :cascade do |t|
    t.integer  "user_id",                 limit: 4,                   null: false
    t.string   "title",                   limit: 255,                 null: false
    t.string   "feed_url",                limit: 255,                 null: false
    t.boolean  "deleted",                             default: false, null: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "auth_user",               limit: 255
    t.string   "auth_encrypted_password", limit: 255
    t.string   "auth_salt",               limit: 255
    t.string   "auth_url",                limit: 255
    t.integer  "display_count",           limit: 4,   default: 5,     null: false
  end

  create_table "portal_layouts", force: :cascade do |t|
    t.integer  "user_id",       limit: 4,               null: false
    t.integer  "column_no",     limit: 4,   default: 0, null: false
    t.integer  "display_order", limit: 4,   default: 0, null: false
    t.string   "gadget_id",     limit: 255,             null: false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "portals", force: :cascade do |t|
    t.integer  "user_id",    limit: 4,                   null: false
    t.string   "name",       limit: 255,                 null: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "deleted",                default: false, null: false
  end

  create_table "preferences", force: :cascade do |t|
    t.integer  "user_id",                       limit: 4,                   null: false
    t.string   "theme",                         limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "use_todo",                                  default: false, null: false
    t.boolean  "use_two_factor_authentication",             default: false, null: false
    t.integer  "default_priority",              limit: 4
  end

  create_table "todos", force: :cascade do |t|
    t.integer  "user_id",    limit: 4,                   null: false
    t.string   "title",      limit: 255,                 null: false
    t.integer  "priority",   limit: 4,                   null: false
    t.boolean  "deleted",                default: false, null: false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "users", force: :cascade do |t|
    t.string   "email",                        limit: 255, default: "",    null: false
    t.string   "encrypted_password",           limit: 255, default: "",    null: false
    t.string   "reset_password_token",         limit: 255
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer  "sign_in_count",                limit: 4,   default: 0
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string   "current_sign_in_ip",           limit: 255
    t.string   "last_sign_in_ip",              limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "admin",                                    default: false, null: false
    t.string   "otp_secret_key",               limit: 255
    t.integer  "second_factor_attempts_count", limit: 4,   default: 0
  end

  add_index "users", ["email"], name: "index_users_on_email", unique: true, using: :btree
  add_index "users", ["otp_secret_key"], name: "index_users_on_otp_secret_key", unique: true, using: :btree
  add_index "users", ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true, using: :btree

  create_table "weathers", force: :cascade do |t|
    t.date     "observation_day",           null: false
    t.integer  "prefecture_no",   limit: 4, null: false
    t.integer  "weather_type",    limit: 4, null: false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

end
