class AddForeignKeyDomainToRealm < ActiveRecord::Migration

  def self.up
    execute "alter table domains add foreign key (realm_id) references realms"
  end

  def self.down
    raise NotImplementedError
  end

end
