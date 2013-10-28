class AddPhoneToAccounts < ActiveRecord::Migration
  def self.up
    add_column :accounts, :phone, :text
  end

  def self.down
    remove_column :accounts, :phone
  end
end
