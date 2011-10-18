class InitialSchema < ActiveRecord::Migration
  def self.up
    create_table :identities do |t|
      t.integer :realm_id, :null => false
      t.integer :primary_account_id
      t.boolean :god, :default => false
      t.datetime :last_login_at
      t.timestamps
    end
    add_index :identities, :realm_id

    create_table :orphaned_identities do |t|
      t.integer :old_id
      t.integer :identity_id
      t.timestamps
    end
    add_index :orphaned_identities, :old_id
    add_index :orphaned_identities, :identity_id

    create_table :realms do |t|
      t.text :title
      t.text :label, :null => false
      t.text :service_keys
      t.timestamps
    end
    add_index :realms, :label, :unique => true

    create_table :accounts do |t|
      t.integer :identity_id
      t.integer :realm_id, :null => false
      t.text :provider, :null => false
      t.text :uid, :null => false
      t.text :token
      t.text :secret

      t.text :nickname
      t.text :name
      t.text :location
      t.text :description
      t.text :profile_url
      t.text :image_url
      t.text :email

      t.datetime :synced_at
      t.timestamps
    end
    add_index :accounts, [:provider, :identity_id, :uid], :unique => true, :name => 'account_uniqueness_index'
  end

  def self.down
    drop_table :accounts
    drop_table :realms
    drop_table :identities
  end
end
