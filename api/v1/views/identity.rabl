object @identity
attributes :id, :god
code(:realm) { |identity| identity.realm.label }
code(:accounts) { |identity| identity.accounts.map(&:provider) }
child :primary_account => :profile do
  attributes :provider, :nickname, :name, :profile_url, :image_url, :description
end