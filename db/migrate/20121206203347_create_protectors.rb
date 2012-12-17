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

    create_table :protectors do |t|
      t.text :callback_url, :null => false
      t.text :path, :null => false
      t.integer :location_id, :null => false
      t.timestamps
    end
    add_index :protectors, :location_id
  end

  def self.down
    drop_table :locations
    drop_table :protectors
  end
end
