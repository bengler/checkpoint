class LastSeenAt < ActiveRecord::Migration
  def self.up
    add_column :identities, :last_seen_at, :date
    remove_column :identities, :last_login_at
  end

  def self.down
  end
end
