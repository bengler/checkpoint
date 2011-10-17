class InitialSchema < ActiveRecord::Migration
  def self.up
    create_table :identities do |t|
      t.text :byline_name
      t.text :byline_url
      t.text :byline_image

      # maybe
      t.text :email, :unique => true
      t.text :mobile, :unique => true

      t.integer :realm_id

      t.text :enrolled_by_provider
      t.integer :enrolled_by_identity_id

      t.integer :kind, :null => false
      t.datetime :active_at # is this first active at or most recently active at?
      t.datetime :synced_at
      t.timestamps
    end

    add_index :identities, :realm_id

    create_table :realms do |t|
      t.text :title
      t.text :label, :null => false
      t.integer :sandbox_id
      t.integer :organization_id
      t.text :api_key, :null => false
      t.text :home_url
      t.text :authentication_success_url
      t.text :authentication_error_url
      t.text :facebook_app_id
      t.text :facebook_page_id
      t.text :facebook_robot_user_uid
      t.text :service_keys
      t.integer :created_by
      t.integer :updated_by
      t.timestamps
    end
    add_index :realms, :label, :unique => true

    create_table :accounts do |t|
      t.integer :realm_id, :null => false
      t.text :provider, :null => false
      t.text :uid, :null => false
      t.text :token
      t.text :secret
      t.integer :identity_id
      t.timestamps
    end
    add_index :accounts, [:realm_id, :provider, :identity_id, :uid], :unique => true, :name => 'account_uniqueness_index'

    create_table :delayed_jobs do |table|
      table.integer  :priority, :default => 0      # Allows some jobs to jump to the front of the queue
      table.integer  :attempts, :default => 0      # Provides for retries, but still fail eventually.
      table.text     :handler                      # YAML-encoded string of the object that will do work
      table.text     :last_error                   # reason for last failure (See Note below)
      table.datetime :run_at                       # When to run. Could be Time.zone.now for immediately, or sometime in the future.
      table.datetime :locked_at                    # Set when a client is working on this object
      table.datetime :failed_at                    # Set when all retries have failed (actually, by default, the record is deleted instead)
      table.string   :locked_by                    # Who is working on this object (if locked)
      table.timestamps
    end
    add_index :delayed_jobs, [:priority, :run_at], :name => 'delayed_jobs_priority'

  end

  def self.down
    drop_table :delayed_jobs
    drop_table :accounts
    drop_table :realms
    drop_table :identities
  end
end
