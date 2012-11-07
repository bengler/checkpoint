class ModifyUniqenessConstraintForAccounts < ActiveRecord::Migration
  def self.up
    execute "drop index account_uniqueness_index"
    add_index :accounts, [:provider, :uid], :unique => true, :name => 'account_uniqueness_index'
  end

  def self.down
  end
end
