class AddPathIndexToBanning < ActiveRecord::Migration
  def self.up
    add_index :bannings, :path
    add_index :bannings, :fingerprint
  end

  def self.down
    remove_index :bannings, :path
    remove_index :bannings, :fingerprint
  end
end
