class AddUniqueIndexToSessionKeys < ActiveRecord::Migration
  def self.up
    # Delete any old sessions that might have duplicated (keep the latest).
    execute "DELETE FROM sessions where id IN (SELECT first_id FROM
                (SELECT min(id) as first_id, identity_id, key, COUNT(identity_id)
                  AS NumOccurIdentity, COUNT(key) as NumOccurKey
                  FROM sessions
                  GROUP BY identity_id, key
                  HAVING ( COUNT(identity_id) > 1 ) AND ( COUNT(key) > 1)) AS foo)"
    add_index :sessions, [:key], :unique => true, :name => 'session_key_uniqueness_index'
  end

  def self.down
    remove_index 'session_key_uniqueness_index'
  end
end
