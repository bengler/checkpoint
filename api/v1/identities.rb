class CheckpointV1 < Sinatra::Base
  helpers do
    def identity_from_param(param)
      (param == "me") ? current_identity : Identity.find(param)
    end
  end

  get '/identities/:id' do
    @identity = identity_from_param(params[:id])
    halt 200, "{}" unless @identity
    render :rabl, :identity, :format => :json
  end

  get '/identities/:id/accounts/:provider' do
    identity = identity_from_param(params[:id])
    halt 500, "No such indentity" unless identity
    identity == current_identity or check_god_credentials(identity.realm_id)
    @account = identity.accounts.where("provider = ?", params[:provider]).first
    halt 200, "{}" unless @account.try(:authorized?)
    render :rabl, :account, :format => :json
  end

end
