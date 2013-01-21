class CreateProtectors < ActiveRecord::Migration
  def self.up
    labels = (0..9).map { |i| "label_#{i}".to_sym }

    create_table :locations do |t|
      labels.each do |label|
        t.text label
      end
      t.timestamps
    end
    add_index :locations, labels, :unique => true, :name => 'index_location_on_labels'

    create_table :callbacks do |t|
      t.text :url, :null => false
      t.text :path, :null => false
      t.integer :location_id, :null => false
      t.timestamps
    end
    add_index :callbacks, :location_id
  end

  def self.down
    drop_table :locations
    drop_table :callbacks
  end
end
