class CheckpointV1 < Sinatra::Base

  # Get an account for an identity
  #
  # @param [String] id the identity id. Can be a numeric id or the string 'me'
  # @param [String] provider the provider of the account, e.g. github, twitter
  # @returns [JSON]
  get '/identities/:id/accounts/:provider' do |id, provider|
    identity = (id == 'me') ? current_identity : Identity.find(id)
    halt 404, "No such indentity" unless identity
    identity == current_identity or check_god_credentials(identity.realm_id)
    account = identity.accounts.where("provider = ?", params[:provider]).first
    halt 200, "{}" unless account.try(:authorized?)
    pg :account, :locals => {:account => account}
  end

end
