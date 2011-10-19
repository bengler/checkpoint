object @identity
attributes :id
code(:realm) { @identity.realm.label }
code(:accounts) { @identity.accounts.map(&:provider) }
child @identity.primary_account => :profile do
  attributes :provider, :nickname, :name, :profile_url, :image_url, :description
end
