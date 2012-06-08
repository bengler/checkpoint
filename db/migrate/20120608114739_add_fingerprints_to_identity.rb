class AddFingerprintsToIdentity < ActiveRecord::Migration

  def self.up
    add_column :identities, :fingerprints, :tsvector
  end

  def self.down
    remove_column :identities, :fingerprints
  end

end
