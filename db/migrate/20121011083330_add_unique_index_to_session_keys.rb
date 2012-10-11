class AddUniqueIndexToSessionKeys < ActiveRecord::Migration
  def self.up
    if ENV['RACK_ENV'] != "production"
      # Remove duplicate session keys
      res = execute "SELECT sessions.id, sessions.identity_id, foo.key FROM sessions
        JOIN (SELECT identity_id, key, COUNT(identity_id)
              AS NumOccurIdentity, COUNT(key) as NumOccurKey
              FROM sessions
              GROUP BY identity_id, key
              HAVING ( COUNT(identity_id) > 1 ) AND ( COUNT(key) > 1)
            ) AS foo
        ON sessions.key = foo.key AND sessions.identity_id = foo.identity_id"
    end
    if res.any? and res[0]['id'].to_i
      res.each do |session|
        id = session['id'].to_i
        execute "DELETE FROM SESSIONS WHERE ID = #{id}"
        puts "Deleted duplicate session key #{id}"
      end
    end
    add_index :sessions, [:key], :unique => true, :name => 'session_key_uniqueness_index'
  end

  def self.down
    remove_index 'session_key_uniqueness_index'
  end
end
