class AddForeignKeys < ActiveRecord::Migration

  def self.up
    execute 'alter table accounts add foreign key (realm_id) references realms'
    execute 'alter table accounts add foreign key (identity_id) references identities'
    execute 'alter table sessions add foreign key (identity_id) references identities'
  end

  def self.down
    execute 'alter table accounts drop constraint accounts_identity_id_fkey'
    execute 'alter table accounts drop constraint accounts_realm_id_fkey'
    execute 'alter table sessions drop constraint sessions_identity_id_fkey'
  end

end
