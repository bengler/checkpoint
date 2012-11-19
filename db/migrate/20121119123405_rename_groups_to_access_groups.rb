class RenameGroupsToAccessGroups < ActiveRecord::Migration
  def self.up
    rename_table :groups, :access_groups
    rename_table :group_subtrees, :access_group_subtrees
    rename_table :group_memberships, :access_group_memberships
    rename_column :access_group_subtrees, :group_id, :access_group_id
    rename_column :access_group_memberships, :group_id, :access_group_id
  end

  def self.down
  end
end
