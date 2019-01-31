class ChangeFingerprintIndexOnIdentity < ActiveRecord::Migration
  def self.up
    execute "create index concurrently index_fingerprints_on_identities_with_gin on identities using gin(fingerprints)"
    execute "drop index index_fingerprints_on_identities"
  end

  def self.down
    execute "create index concurrently index_fingerprints_on_identities on identities using gist(fingerprints)"
    execute "drop index index_fingerprints_on_identities_with_gin"
  end
end
