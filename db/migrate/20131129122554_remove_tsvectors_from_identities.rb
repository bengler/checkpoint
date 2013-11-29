class RemoveTsvectorsFromIdentities < ActiveRecord::Migration
  def up
    remove_column :identities, :tags
    remove_column :identities, :fingerprints
  end

  def down
    add_column :identities, :tags, :tsvector
    add_column :identities, :fingerprints, :tsvector
  end
end
