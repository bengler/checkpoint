class CreateIdentityFingerprints < ActiveRecord::Migration

  def self.up
    create_table :identity_fingerprints do |t|
      t.integer :identity_id, :null => false
      t.text :fingerprint, :null => false
    end

    # Identity.where("fingerprints IS NOT NULL").each_with_index do |identity, index|
    #   identity.fingerprints.each do |fingerprint|
    #     IdentityFingerprint.create identity_id: identity.id, fingerprint: fingerprint
    #   end
    # end

    add_index :identity_fingerprints, [:identity_id]
    add_index :identity_fingerprints, [:fingerprint]
  end

  def self.down
    drop_table :identity_fingerprints
  end

end
