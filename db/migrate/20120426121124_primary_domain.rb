class PrimaryDomain < ActiveRecord::Migration
  def self.up

    # Add primary_domain to all realms. For lack of a better algorithm, pick the shortest domain name 
    # attached to each realm.
    add_column :realms, :primary_domain_id, :integer 
    Realm.all.each do |realm|
      realm.primary_domain = Domain.first(:conditions => {:realm_id => realm.id}, :order => "length(name)")
      realm.save!
    end
    execute "alter table realms add foreign key (primary_domain_id) references domains"

    # Oops. Domains did not have timestamps.
    add_column :domains, :created_at, :timestamp
    add_column :domains, :updated_at, :timestamp
    execute "update domains set created_at = now(), updated_at = now()"
  end

  def self.down
    remove_column :realms
  end
end
