class UniqueAccountsPerRealm < ActiveRecord::Migration
  def self.up
    # Several identical accounts within a single realm makes it impossible
    # to determine which identity a user is trying to log into. Must be unique
    # across the realm.
    execute "drop index account_uniqueness_index"
    add_index :accounts, [:provider, :realm_id, :uid], :unique => true, :name => 'account_uniqueness_index'
  end

  def self.down
  end
end
