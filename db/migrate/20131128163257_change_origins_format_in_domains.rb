class ChangeOriginsFormatInDomains < ActiveRecord::Migration

  def self.up
    change_column :domains, :origins, :text
  end

  def self.down
    change_column :domains, :origins, :tsvector
  end

end
