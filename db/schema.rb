# encoding: ISO-8859-1
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

ActiveRecord::Schema.define(:version => 20131128163257) do

  create_table "access_group_memberships", :force => true do |t|
    t.integer  "access_group_id", :null => false
    t.integer  "identity_id",     :null => false
    t.datetime "created_at",      :null => false
    t.datetime "updated_at",      :null => false
  end

  add_index "access_group_memberships", ["access_group_id", "identity_id"], :name => "group_membership_identity_uniqueness_index", :unique => true

  create_table "access_group_subtrees", :force => true do |t|
    t.integer  "access_group_id", :null => false
    t.text     "location",        :null => false
    t.datetime "created_at",      :null => false
    t.datetime "updated_at",      :null => false
  end

  add_index "access_group_subtrees", ["access_group_id", "location"], :name => "group_subtree_location_uniqueness_index", :unique => true
  add_index "access_group_subtrees", ["access_group_id"], :name => "index_group_subtrees_on_group_id"

  create_table "access_groups", :force => true do |t|
    t.integer  "realm_id",   :null => false
    t.text     "label"
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
  end

  add_index "access_groups", ["realm_id", "label"], :name => "group_label_uniqueness_index", :unique => true
  add_index "access_groups", ["realm_id"], :name => "index_groups_on_realm_id"

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
    t.datetime "created_at",  :null => false
    t.datetime "updated_at",  :null => false
    t.text     "phone"
  end

  add_index "accounts", ["identity_id"], :name => "index_accounts_on_identity_id"
  add_index "accounts", ["provider", "realm_id", "uid"], :name => "account_uniqueness_index", :unique => true
  add_index "accounts", ["realm_id"], :name => "index_accounts_on_realm_id"

  create_table "bannings", :force => true do |t|
    t.text     "fingerprint"
    t.text     "path"
    t.integer  "location_id"
    t.integer  "realm_id"
    t.datetime "created_at",  :null => false
    t.datetime "updated_at",  :null => false
  end

  add_index "bannings", ["fingerprint", "path"], :name => "index_bannings_on_fingerprint_and_path"

  create_table "callbacks", :force => true do |t|
    t.text     "url",         :null => false
    t.text     "path",        :null => false
    t.integer  "location_id", :null => false
    t.datetime "created_at",  :null => false
    t.datetime "updated_at",  :null => false
  end

  add_index "callbacks", ["location_id"], :name => "index_callbacks_on_location_id"

  create_table "domains", :force => true do |t|
    t.text     "name"
    t.integer  "realm_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.text     "origins"
  end

  add_index "domains", ["name"], :name => "index_domains_on_name", :unique => true
  add_index "domains", ["realm_id"], :name => "index_domains_on_realm_id"

  create_table "identities", :force => true do |t|
    t.integer  "realm_id",                              :null => false
    t.integer  "primary_account_id"
    t.boolean  "god",                :default => false
    t.datetime "created_at",                            :null => false
    t.datetime "updated_at",                            :null => false
    t.date     "last_seen_on"
    t.tsvector "fingerprints"
    t.tsvector "tags"
  end

  add_index "identities", ["fingerprints"], :name => "index_fingerprints_on_identities"
  add_index "identities", ["realm_id"], :name => "index_identities_on_realm_id"

  create_table "identity_fingerprints", :force => true do |t|
    t.integer "identity_id", :null => false
    t.text    "fingerprint", :null => false
  end

  add_index "identity_fingerprints", ["fingerprint"], :name => "index_identity_fingerprints_on_fingerprint"
  add_index "identity_fingerprints", ["identity_id"], :name => "index_identity_fingerprints_on_identity_id"

  create_table "identity_ips", :force => true do |t|
    t.text     "address",     :null => false
    t.integer  "identity_id", :null => false
    t.datetime "created_at",  :null => false
    t.datetime "updated_at",  :null => false
  end

  add_index "identity_ips", ["address"], :name => "index_identity_ips_on_address"
  add_index "identity_ips", ["identity_id"], :name => "index_identity_ips_on_identity_id"

  create_table "identity_tags", :force => true do |t|
    t.integer "identity_id", :null => false
    t.text    "tag",         :null => false
  end

  add_index "identity_tags", ["identity_id"], :name => "index_identity_tags_on_identity_id"
  add_index "identity_tags", ["tag"], :name => "index_identity_tags_on_tag"

  create_table "locations", :force => true do |t|
    t.text     "label_0"
    t.text     "label_1"
    t.text     "label_2"
    t.text     "label_3"
    t.text     "label_4"
    t.text     "label_5"
    t.text     "label_6"
    t.text     "label_7"
    t.text     "label_8"
    t.text     "label_9"
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
  end

  add_index "locations", ["label_0", "label_1", "label_2", "label_3", "label_4", "label_5", "label_6", "label_7", "label_8", "label_9"], :name => "index_location_on_labels", :unique => true

  create_table "realms", :force => true do |t|
    t.text     "title"
    t.text     "label",             :null => false
    t.text     "service_keys"
    t.datetime "created_at",        :null => false
    t.datetime "updated_at",        :null => false
    t.integer  "primary_domain_id"
  end

  add_index "realms", ["label"], :name => "index_realms_on_label", :unique => true

  create_table "sessions", :force => true do |t|
    t.integer  "identity_id"
    t.text     "key"
    t.datetime "created_at",  :null => false
    t.datetime "updated_at",  :null => false
  end

  add_index "sessions", ["identity_id"], :name => "index_sessions_on_identity_id"
  add_index "sessions", ["key"], :name => "index_sessions_on_key"
  add_index "sessions", ["key"], :name => "session_key_uniqueness_index", :unique => true

end
