class AddTagsToIdentities < ActiveRecord::Migration

  def self.up
    add_column :identities, :tags, :tsvector
  end

  def self.down
    remove_column :identities, :tags
  end

end