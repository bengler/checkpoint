class AddFingerprintsIndex < ActiveRecord::Migration
  def self.up
    execute "create index index_fingerprints_on_identities on identities using gist(fingerprints)"
  end

  def self.down
    execute "drop index index_fingerprints_on_identities"
  end
end
