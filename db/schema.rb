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
    t.integer  "identity_id"
    t.integer  "realm_id",    :null => false
    t.text     "provider",    :null => false
    t.text     "uid",         :null => false
    t.text     "token"
    t.text     "secret"
    t.text     "nickname"
    t.text     "name"
    t.text     "location"
    t.text     "description"
    t.text     "profile_url"
    t.text     "image_url"
    t.text     "email"
    t.datetime "synced_at"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "accounts", ["provider", "identity_id", "uid"], :name => "account_uniqueness_index", :unique => true

  create_table "domains", :force => true do |t|
    t.text    "name"
    t.integer "realm_id"
  end

  add_index "domains", ["name"], :name => "index_domains_on_name", :unique => true
  add_index "domains", ["realm_id"], :name => "index_domains_on_realm_id"

  create_table "identities", :force => true do |t|
    t.integer  "realm_id",                              :null => false
    t.integer  "primary_account_id"
    t.boolean  "god",                :default => false
    t.datetime "last_login_at"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "identities", ["realm_id"], :name => "index_identities_on_realm_id"

  create_table "realms", :force => true do |t|
    t.text     "title"
    t.text     "label",        :null => false
    t.text     "service_keys"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "realms", ["label"], :name => "index_realms_on_label", :unique => true

end
