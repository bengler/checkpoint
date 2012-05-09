class AddIndexes < ActiveRecord::Migration

  def self.up
    add_index :sessions, :key
    add_index :accounts, :realm_id
    add_index :accounts, :identity_id
  end

  def self.down
    remove_index :sessions, :key
    remove_index :accounts, :identity_id
    remove_index :accounts, :realm_id
  end

end
