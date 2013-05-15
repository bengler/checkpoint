class AddOriginsFieldToDomains < ActiveRecord::Migration
  def self.up
  	add_column :domains, :origins, :tsvector
  end

  def self.down
  	remove_column :domains, :origins
  end
end
