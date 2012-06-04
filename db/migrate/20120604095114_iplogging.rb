class Iplogging < ActiveRecord::Migration
  def self.up
    create_table :identity_ips do |t|
      t.text :address, :null => false
      t.integer :identity_id, :null => false
      t.timestamps
    end
    add_index :identity_ips, :address
    add_index :identity_ips, :identity_id
  end

  def self.down
  end
end
