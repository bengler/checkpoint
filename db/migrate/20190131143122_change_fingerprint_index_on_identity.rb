class ChangeFingerprintIndexOnIdentity < ActiveRecord::Migration
  def self.up
    execute "drop index index_fingerprints_on_identities"
    execute "create index index_fingerprints_on_identities on identities using gin(fingerprints)"
  end

  def self.down
    execute "drop index index_fingerprints_on_identities"
    execute "create index index_fingerprints_on_identities on identities using gist(fingerprints)"
  end
end
