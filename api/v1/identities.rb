class CheckpointV1 < Sinatra::Base
  helpers do
    def identity_from_param(param)
      (param == "me") ? current_identity : Identity.find(param)
    end
  end

  get '/identities/:id' do
    identity_from_param(params[:id]).try(:to_json)
  end

  get '/identities/:id/credentials/:provider' do
    identity = identity_from_param(params[:id])
    halt 403, "Will only provide keys for gods or self" unless current_identity.god? || current_identity == identity
    account = identity.accounts.where("provider = ?", params[:provider]).first
    halt 404, "No keys for provider" unless account && account.authorized?
    {
      identity: identity.id,
      provider: account.provider,
      uid: account.uid,
      token: account.token,
      secret: account.secret
    }.to_json
  end

end
