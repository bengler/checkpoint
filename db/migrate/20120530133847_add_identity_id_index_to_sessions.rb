class AddIdentityIdIndexToSessions < ActiveRecord::Migration
  def self.up
    add_index :sessions, :identity_id
  end

  def self.down
    remove_index :sessions, :identity_id
  end
end
