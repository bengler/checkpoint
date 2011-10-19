class CheckpointV1 < Sinatra::Base
  helpers do
    def identity_from_param(param)
      identity = (param == "me") ? current_identity : Identity.find(param)
      halt 404, "No such identity" unless identity
      identity
    end
  end

  get '/identities/:id' do
    @identity = identity_from_param(params[:id])
    render :rabl, :identity, :format => :json
  end

  get '/identities/:id/accounts/:provider' do
    identity = identity_from_param(params[:id])
    identity == current_identity or check_god_credentials(identity.realm_id)
    @account = identity.accounts.where("provider = ?", params[:provider]).first
    halt 404, "No keys for provider" unless @account.try(:authorized?)
    render :rabl, :account, :format => :json
  end

end
