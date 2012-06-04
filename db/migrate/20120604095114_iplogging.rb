class Iplogging < ActiveRecord::Migration
  def self.up
    create_table :session_ips do |t|
      t.text :address, :null => false
      t.text :key, :null => false
      t.timestamps
    end
    add_index :session_ips, :address
    add_index :session_ips, :key
  end

  def self.down
  end
end
