class CheckpointV1 < Sinatra::Base

  get '/identities/:id' do |id|
    if id =~ /\,/
      # Retrieve a list of identities      
      ids = id.split(/\s*,\s*/).compact
      @identities = Identity.cached_find_all_by_id(ids)
      render :rabl, :identities, :format => :json
    else
      # Retrieve a single identity
      @identity = (id == 'me') ? current_identity : Identity.cached_find_by_id(id)
      halt 200, "{}" unless @identity
      render :rabl, :identity, :format => :json
    end
  end

  get '/identities/:id/accounts/:provider' do |id, provider|
    identity = (id == 'me') ? current_identity : Identity.find(id)
    halt 404, "No such indentity" unless identity
    identity == current_identity or check_god_credentials(identity.realm_id)
    @account = identity.accounts.where("provider = ?", params[:provider]).first
    halt 200, "{}" unless @account.try(:authorized?)
    render :rabl, :account, :format => :json
  end

end
