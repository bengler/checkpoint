class CreateCompoundIndexOnIdentityIps < ActiveRecord::Migration

  def change
    execute "create index concurrently index_identity_ips_on_address_and_identity_id " \
      "on identity_ips (address, identity_id)"
    execute "drop index concurrently index_identity_ips_on_identity_id"
    execute "drop index concurrently index_identity_ips_on_address"
  end

end
