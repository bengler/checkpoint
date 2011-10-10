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

ActiveRecord::Schema.define(:version => 20110926230557) do

  create_table "accounts", :force => true do |t|
    t.integer  "identity_id", :null => false
    t.integer  "realm_id",    :null => false
    t.text     "provider",    :null => false
    t.text     "uid",         :null => false
    t.text     "token"
    t.text     "secret"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "accounts", ["realm_id", "provider", "identity_id", "uid"], :name => "account_uniqueness_index", :unique => true

  create_table "delayed_jobs", :force => true do |t|
    t.integer  "priority",   :default => 0
    t.integer  "attempts",   :default => 0
    t.text     "handler"
    t.text     "last_error"
    t.datetime "run_at"
    t.datetime "locked_at"
    t.datetime "failed_at"
    t.string   "locked_by"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "delayed_jobs", ["priority", "run_at"], :name => "delayed_jobs_priority"

  create_table "identities", :force => true do |t|
    t.text     "byline_name"
    t.text     "byline_url"
    t.text     "byline_image"
    t.text     "email"
    t.text     "mobile"
    t.integer  "realm_id"
    t.text     "enrolled_by_provider"
    t.integer  "enrolled_by_identity_id"
    t.integer  "kind",                    :null => false
    t.datetime "active_at"
    t.datetime "synced_at"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "identities", ["realm_id"], :name => "index_identities_on_realm_id"

  create_table "realms", :force => true do |t|
    t.text     "title"
    t.text     "label",                      :null => false
    t.integer  "sandbox_id"
    t.integer  "organization_id"
    t.text     "api_key",                    :null => false
    t.text     "home_url"
    t.text     "authentication_success_url"
    t.text     "authentication_error_url"
    t.text     "facebook_app_id"
    t.text     "facebook_page_id"
    t.text     "facebook_robot_user_uid"
    t.text     "service_keys"
    t.integer  "created_by"
    t.integer  "updated_by"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "realms", ["label"], :name => "index_realms_on_label", :unique => true

end
