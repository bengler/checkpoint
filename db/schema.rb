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

ActiveRecord::Schema.define(:version => 20140120093822) do

  create_table "access_group_memberships", :force => true do |t|
    t.integer  "access_group_id", :null => false
    t.integer  "identity_id",     :null => false
    t.datetime "created_at",      :null => false
    t.datetime "updated_at",      :null => false
  end

  add_index "access_group_memberships", ["access_group_id", "identity_id"], :name => "group_membership_identity_uniqueness_index", :unique => true

  create_table "access_group_subtrees", :force => true do |t|
    t.integer  "access_group_id", :null => false
    t.string   "location",        :null => false
    t.datetime "created_at",      :null => false
    t.datetime "updated_at",      :null => false
  end

  add_index "access_group_subtrees", ["access_group_id", "location"], :name => "group_subtree_location_uniqueness_index", :unique => true
  add_index "access_group_subtrees", ["access_group_id"], :name => "index_group_subtrees_on_group_id"

  create_table "access_groups", :force => true do |t|
    t.integer  "realm_id",   :null => false
    t.string   "label"
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
  end

  add_index "access_groups", ["realm_id", "label"], :name => "group_label_uniqueness_index", :unique => true
  add_index "access_groups", ["realm_id"], :name => "index_groups_on_realm_id"

  create_table "accounts", :force => true do |t|
    t.integer  "identity_id"
    t.integer  "realm_id",    :null => false
    t.string   "provider",    :null => false
    t.string   "uid",         :null => false
    t.string   "token"
    t.string   "secret"
    t.string   "nickname"
    t.string   "name"
    t.string   "location"
    t.text     "description"
    t.string   "profile_url"
    t.string   "image_url"
    t.string   "email"
    t.datetime "synced_at"
    t.datetime "created_at",  :null => false
    t.datetime "updated_at",  :null => false
    t.string   "phone"
  end

  add_index "accounts", ["identity_id"], :name => "index_accounts_on_identity_id"
  add_index "accounts", ["provider", "realm_id", "uid"], :name => "account_uniqueness_index", :unique => true
  add_index "accounts", ["realm_id"], :name => "index_accounts_on_realm_id"

  create_table "bannings", :force => true do |t|
    t.string   "fingerprint"
    t.string   "path"
    t.integer  "location_id"
    t.integer  "realm_id"
    t.datetime "created_at",  :null => false
    t.datetime "updated_at",  :null => false
  end

  add_index "bannings", ["fingerprint", "path"], :name => "index_bannings_on_fingerprint_and_path"

  create_table "callbacks", :force => true do |t|
    t.string   "url",         :null => false
    t.string   "path",        :null => false
    t.integer  "location_id", :null => false
    t.datetime "created_at",  :null => false
    t.datetime "updated_at",  :null => false
  end

  add_index "callbacks", ["location_id"], :name => "index_callbacks_on_location_id"

  create_table "domain_origins", :force => true do |t|
    t.integer "domain_id", :null => false
    t.string  "host",      :null => false
  end

  create_table "domains", :force => true do |t|
    t.string   "name"
    t.integer  "realm_id"
    t.datetime "created_at"
    t.datetime "updated_at"
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
  end

  add_index "identities", ["realm_id"], :name => "index_identities_on_realm_id"

  create_table "identity_fingerprints", :force => true do |t|
    t.integer "identity_id", :null => false
    t.string  "fingerprint", :null => false
  end

  add_index "identity_fingerprints", ["fingerprint"], :name => "index_identity_fingerprints_on_fingerprint"
  add_index "identity_fingerprints", ["identity_id"], :name => "index_identity_fingerprints_on_identity_id"

  create_table "identity_ips", :force => true do |t|
    t.string   "address",     :null => false
    t.integer  "identity_id", :null => false
    t.datetime "created_at",  :null => false
    t.datetime "updated_at",  :null => false
  end

  add_index "identity_ips", ["address"], :name => "index_identity_ips_on_address"
  add_index "identity_ips", ["identity_id"], :name => "index_identity_ips_on_identity_id"

  create_table "identity_tags", :force => true do |t|
    t.integer "identity_id", :null => false
    t.string  "tag",         :null => false
  end

  add_index "identity_tags", ["identity_id"], :name => "index_identity_tags_on_identity_id"
  add_index "identity_tags", ["tag"], :name => "index_identity_tags_on_tag"

  create_table "locations", :force => true do |t|
    t.string   "label_0",    :limit => 100
    t.string   "label_1",    :limit => 100
    t.string   "label_2",    :limit => 100
    t.string   "label_3",    :limit => 100
    t.string   "label_4",    :limit => 100
    t.string   "label_5",    :limit => 100
    t.string   "label_6",    :limit => 100
    t.string   "label_7",    :limit => 100
    t.string   "label_8",    :limit => 100
    t.string   "label_9",    :limit => 100
    t.datetime "created_at",                :null => false
    t.datetime "updated_at",                :null => false
  end

  add_index "locations", ["label_0", "label_1", "label_2", "label_3", "label_4", "label_5", "label_6", "label_7", "label_8", "label_9"], :name => "index_location_on_labels", :unique => true

  create_table "origins", :force => true do |t|
    t.integer "domain_id", :null => false
    t.string  "host",      :null => false
  end

  add_index "origins", ["domain_id"], :name => "index_origins_on_domain_id"

  create_table "realms", :force => true do |t|
    t.string   "title"
    t.string   "label",             :null => false
    t.text     "service_keys"
    t.datetime "created_at",        :null => false
    t.datetime "updated_at",        :null => false
    t.integer  "primary_domain_id"
  end

  add_index "realms", ["label"], :name => "index_realms_on_label", :unique => true

  create_table "sessions", :force => true do |t|
    t.integer  "identity_id"
    t.string   "key"
    t.datetime "created_at",  :null => false
    t.datetime "updated_at",  :null => false
  end

  add_index "sessions", ["identity_id"], :name => "index_sessions_on_identity_id"
  add_index "sessions", ["key"], :name => "index_sessions_on_key"
  add_index "sessions", ["key"], :name => "session_key_uniqueness_index", :unique => true

end
