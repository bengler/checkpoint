class CreateBannings < ActiveRecord::Migration
  def self.up
    create_table :bannings do |t|
      t.text :fingerprint
      t.text :path
      t.integer :location_id
      t.integer :realm_id
      t.timestamps
    end
    add_index :bannings, [:fingerprint, :path]
  end

  def self.down
    drop_table :bannings
  end
end
