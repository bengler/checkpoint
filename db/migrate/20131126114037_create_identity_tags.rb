class CreateIdentityTags < ActiveRecord::Migration

  def self.up
    create_table :identity_tags do |t|
      t.integer :identity_id, :null => false
      t.text :tag, :null => false
    end

    Identity.where("tags IS NOT NULL").each_with_index do |identity, index|
      identity.tags.each do |tag|
        IdentityTag.create identity_id: identity.id, tag: tag
      end
    end

    add_index :identity_tags, [:identity_id]
    add_index :identity_tags, [:tag]
  end

  def self.down
    drop_table :identity_tags
  end

end
