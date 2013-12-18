class CreateOrigins < ActiveRecord::Migration

  def self.up
    create_table :origins do |t|
      t.integer :domain_id, :null => false
      t.string  :host, :null => false
    end
    add_index :origins, [:domain_id]

    query = 'SELECT id, origins FROM domains WHERE origins IS NOT NULL'
    select_all(query).each do |row|
      row['origins'].split(',').each do |host|
        Origin.create(domain_id: row['id'], host: host)
      end
    end

    remove_column :domains, :origins
  end

  def self.down
    add_column :domains, :origins, :text

    Origin.all.group_by(&:domain_id).each do |domain_id, origins|
      value = origins.map(&:host).join(',')
      update "UPDATE domains SET origins = '#{value}' WHERE id = #{domain_id}"
    end

    drop_table :origins
  end

end
