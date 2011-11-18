class CheckpointV1 < Sinatra::Base

  get '/identities/:id' do |id|
    if id == 'me'
      current_identity
    elsif id =~ /\,/
      # Retrieve a list of identities      
      ids = id.split(/\s*,\s*/).compact
      found_identities = Identity.find_all_by_id(ids)
      #raise found_identities.inspect
      @identities = ids.collect do |id|
        found_identities.find {|i| i.id == id.to_i}
      end
      render :rabl, :identities, :format => :json
    else
      # Retrieve a single identity
      @identity = Identity.find(id)
      halt 404, "{}" unless @identity
      render :rabl, :identity, :format => :json
    end
  end

  get '/identities/:id/accounts/:provider' do |id, provider|
    identity = id == 'me' ? current_identity : Identity.find(id)
    halt 500, "No such indentity" unless identity
    identity == current_identity or check_god_credentials(identity.realm_id)
    @account = identity.accounts.where("provider = ?", params[:provider]).first
    halt 200, "{}" unless @account.try(:authorized?)
    render :rabl, :account, :format => :json
  end

end
