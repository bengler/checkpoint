class CheckpointV1 < Sinatra::Base

  get '/identities/:id/accounts/:provider' do |id, provider|
    identity = (id == 'me') ? current_identity : Identity.find(id)
    halt 404, "No such indentity" unless identity
    identity == current_identity or check_god_credentials(identity.realm_id)
    account = identity.accounts.where("provider = ?", params[:provider]).first
    halt 200, "{}" unless account.try(:authorized?)
    pg :account, :locals => {:account => account}
  end

end
