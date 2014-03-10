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
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 20140310032013) do

  create_table "bookmarks", :force => true do |t|
    t.integer  "user_id",                       :null => false
    t.string   "title",                         :null => false
    t.string   "url",                           :null => false
    t.boolean  "deleted",    :default => false, :null => false
    t.datetime "created_at",                    :null => false
    t.datetime "updated_at",                    :null => false
  end

  create_table "calendars", :force => true do |t|
    t.integer  "user_id",                       :null => false
    t.string   "title"
    t.boolean  "deleted",    :default => false, :null => false
    t.datetime "created_at",                    :null => false
    t.datetime "updated_at",                    :null => false
  end

  create_table "feeds", :force => true do |t|
    t.integer  "user_id",                                    :null => false
    t.string   "title",                                      :null => false
    t.string   "feed_url",                                   :null => false
    t.boolean  "deleted",                 :default => false, :null => false
    t.datetime "created_at",                                 :null => false
    t.datetime "updated_at",                                 :null => false
    t.string   "auth_user"
    t.string   "auth_encrypted_password"
    t.string   "auth_salt"
    t.string   "auth_url"
    t.integer  "display_count",                              :null => false
  end

  create_table "portal_layouts", :force => true do |t|
    t.integer  "user_id",                      :null => false
    t.integer  "column_no",     :default => 0, :null => false
    t.integer  "display_order", :default => 0, :null => false
    t.string   "gadget_id",                    :null => false
    t.datetime "created_at",                   :null => false
    t.datetime "updated_at",                   :null => false
  end

  create_table "portals", :force => true do |t|
    t.integer  "user_id",                       :null => false
    t.string   "name",                          :null => false
    t.datetime "created_at",                    :null => false
    t.datetime "updated_at",                    :null => false
    t.boolean  "deleted",    :default => false, :null => false
  end

  create_table "preferences", :force => true do |t|
    t.integer  "user_id"
    t.string   "theme"
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
  end

  create_table "todos", :force => true do |t|
    t.integer  "user_id",                       :null => false
    t.string   "title",                         :null => false
    t.integer  "priority",                      :null => false
    t.boolean  "deleted",    :default => false, :null => false
    t.datetime "created_at",                    :null => false
    t.datetime "updated_at",                    :null => false
  end

  create_table "users", :force => true do |t|
    t.string   "email",                  :default => "", :null => false
    t.string   "encrypted_password",     :default => "", :null => false
    t.string   "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer  "sign_in_count",          :default => 0
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string   "current_sign_in_ip"
    t.string   "last_sign_in_ip"
    t.datetime "created_at",                             :null => false
    t.datetime "updated_at",                             :null => false
  end

  add_index "users", ["email"], :name => "index_users_on_email", :unique => true
  add_index "users", ["reset_password_token"], :name => "index_users_on_reset_password_token", :unique => true

end
