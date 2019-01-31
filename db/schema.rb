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

ActiveRecord::Schema.define(version: 20190131143122) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "access_group_memberships", force: :cascade do |t|
    t.integer  "access_group_id", null: false
    t.integer  "identity_id",     null: false
    t.datetime "created_at",      null: false
    t.datetime "updated_at",      null: false
  end

  add_index "access_group_memberships", ["access_group_id", "identity_id"], name: "group_membership_identity_uniqueness_index", unique: true, using: :btree

  create_table "access_group_subtrees", force: :cascade do |t|
    t.integer  "access_group_id", null: false
    t.text     "location",        null: false
    t.datetime "created_at",      null: false
    t.datetime "updated_at",      null: false
  end

  add_index "access_group_subtrees", ["access_group_id", "location"], name: "group_subtree_location_uniqueness_index", unique: true, using: :btree
  add_index "access_group_subtrees", ["access_group_id"], name: "index_group_subtrees_on_group_id", using: :btree

  create_table "access_groups", force: :cascade do |t|
    t.integer  "realm_id",   null: false
    t.text     "label"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  add_index "access_groups", ["realm_id", "label"], name: "group_label_uniqueness_index", unique: true, using: :btree
  add_index "access_groups", ["realm_id"], name: "index_groups_on_realm_id", using: :btree

  create_table "accounts", force: :cascade do |t|
    t.integer  "identity_id"
    t.integer  "realm_id",    null: false
    t.text     "provider",    null: false
    t.text     "uid",         null: false
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
    t.text     "phone"
  end

  add_index "accounts", ["identity_id"], name: "index_accounts_on_identity_id", using: :btree
  add_index "accounts", ["provider", "realm_id", "uid"], name: "account_uniqueness_index", unique: true, using: :btree
  add_index "accounts", ["realm_id"], name: "index_accounts_on_realm_id", using: :btree

  create_table "bannings", force: :cascade do |t|
    t.text     "fingerprint"
    t.text     "path"
    t.integer  "location_id"
    t.integer  "realm_id"
    t.datetime "created_at",  null: false
    t.datetime "updated_at",  null: false
  end

  add_index "bannings", ["fingerprint", "path"], name: "index_bannings_on_fingerprint_and_path", using: :btree
  add_index "bannings", ["fingerprint"], name: "index_bannings_on_fingerprint", using: :btree
  add_index "bannings", ["path"], name: "index_bannings_on_path", using: :btree

  create_table "callbacks", force: :cascade do |t|
    t.text     "url",         null: false
    t.text     "path",        null: false
    t.integer  "location_id", null: false
    t.datetime "created_at",  null: false
    t.datetime "updated_at",  null: false
  end

  add_index "callbacks", ["location_id"], name: "index_callbacks_on_location_id", using: :btree

  create_table "domains", force: :cascade do |t|
    t.text     "name"
    t.integer  "realm_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.tsvector "origins"
  end

  add_index "domains", ["name"], name: "index_domains_on_name", unique: true, using: :btree
  add_index "domains", ["realm_id"], name: "index_domains_on_realm_id", using: :btree

  create_table "identities", force: :cascade do |t|
    t.integer  "realm_id",                           null: false
    t.integer  "primary_account_id"
    t.boolean  "god",                default: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.date     "last_seen_on"
    t.tsvector "fingerprints"
    t.tsvector "tags"
  end

  add_index "identities", ["fingerprints"], name: "index_fingerprints_on_identities", using: :gin
  add_index "identities", ["primary_account_id"], name: "index_identities_on_primary_account_id", using: :btree
  add_index "identities", ["realm_id"], name: "index_identities_on_realm_id", using: :btree

  create_table "identity_ips", force: :cascade do |t|
    t.text     "address",     null: false
    t.integer  "identity_id", null: false
    t.datetime "created_at",  null: false
    t.datetime "updated_at",  null: false
  end

  add_index "identity_ips", ["address", "identity_id"], name: "index_identity_ips_on_address_and_identity_id", using: :btree

  create_table "locations", force: :cascade do |t|
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
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  add_index "locations", ["label_0", "label_1", "label_2", "label_3", "label_4", "label_5", "label_6", "label_7", "label_8", "label_9"], name: "index_location_on_labels", unique: true, using: :btree

  create_table "realms", force: :cascade do |t|
    t.text     "title"
    t.text     "label",             null: false
    t.text     "service_keys"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "primary_domain_id"
  end

  add_index "realms", ["label"], name: "index_realms_on_label", unique: true, using: :btree

  create_table "sessions", force: :cascade do |t|
    t.integer  "identity_id"
    t.text     "key"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "sessions", ["identity_id"], name: "index_sessions_on_identity_id", using: :btree
  add_index "sessions", ["key"], name: "index_sessions_on_key", using: :btree
  add_index "sessions", ["key"], name: "session_key_uniqueness_index", unique: true, using: :btree

  add_foreign_key "access_group_memberships", "access_groups", name: "group_memberships_group_id_fkey"
  add_foreign_key "access_group_memberships", "identities", name: "group_memberships_identity_id_fkey"
  add_foreign_key "access_group_subtrees", "access_groups", name: "group_subtrees_group_id_fkey"
  add_foreign_key "access_groups", "realms", name: "groups_realm_id_fkey"
  add_foreign_key "accounts", "identities", name: "accounts_identity_id_fkey"
  add_foreign_key "accounts", "realms", name: "accounts_realm_id_fkey"
  add_foreign_key "domains", "realms", name: "domains_realm_id_fkey"
  add_foreign_key "realms", "domains", column: "primary_domain_id", name: "realms_primary_domain_id_fkey"
  add_foreign_key "sessions", "identities", name: "sessions_identity_id_fkey"
end
