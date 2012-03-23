class CheckpointV1 < Sinatra::Base

  # Get an account for an identity
  #
  # @param [String] id the identity id. Can be a numeric id or the string 'me'
  # @param [String] provider the provider of the account, e.g. github, twitter
  # @returns [JSON]
  get '/identities/:id/accounts/:provider' do |id, provider|
    identity = (id == 'me') ? current_identity : Identity.find(id)
    halt 404, "No such identity" unless identity
    identity == current_identity or check_god_credentials(identity.realm_id)
    account = identity.accounts.where("provider = ?", params[:provider]).first
    halt 200, "{}" unless account.try(:authorized?)
    pg :account, :locals => {:account => account}
  end


  # Get an account by provider and uid. Only provided to god-identities.
  #
  # @returns [JSON]
  get '/accounts/:provider/:uid' do |provider, uid|
    check_god_credentials(current_identity.realm_id)
    account = Account.where(:realm_id => current_identity.realm_id, :provider => provider, :uid => uid).first
    halt 404, "No such account" unless account
    pg :account, :locals => {:account => account}
  end

end
