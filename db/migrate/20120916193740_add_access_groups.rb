class AddAccessGroups < ActiveRecord::Migration
  def self.up
    create_table :groups do |t|
      t.integer :realm_id, :null => false
      t.text :label
      t.timestamps
    end
    add_index :groups, :realm_id
    add_index :groups, [:realm_id, :label], :unique => true, :name => 'group_label_uniqueness_index'
    execute 'alter table groups add foreign key (realm_id) references realms'

    create_table :group_memberships do |t|
      t.integer :group_id, :null => false
      t.integer :identity_id, :null => false
    end
    add_index :group_memberships, [:group_id, :identity_id], :unique => true, :name => "group_membership_identity_uniqueness_index"
    execute 'alter table group_memberships add foreign key (group_id) references groups'
    execute 'alter table group_memberships add foreign key (identity_id) references identities'

    create_table :group_subtrees do |t|
      t.integer :group_id, :null => false
      t.text :location, :null => false
    end
    add_index :group_subtrees, :group_id
    add_index :group_subtrees, [:group_id, :location], :unique => true, :name => 'group_subtree_location_uniqueness_index'
    execute 'alter table group_subtrees add foreign key (group_id) references groups'
  end

  def self.down
    drop_table :groups
    drop_table :group_memberships
    drop_table :group_subtrees
  end
end
