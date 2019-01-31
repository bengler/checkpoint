class AddPrimaryAccountIndexToIdentity < ActiveRecord::Migration
  def self.up
    add_index :identities, :primary_account_id
  end

  def self.down
    remove_index :identities, :primary_account_id
  end
end
