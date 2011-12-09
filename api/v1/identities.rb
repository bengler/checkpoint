class CheckpointV1 < Sinatra::Base

  helpers do
    def create_identity(identity_data, account_data)
      attributes = identity_data || {}
      identity = Identity.create! attributes.merge(:realm => current_realm)

      if account_data
        attributes = account_data.merge(:realm => current_realm, :identity => identity)
        Account.create! attributes
        identity.ensure_primary_account
        identity.save!
      end
      identity
    end
  end

  # TODO
  # [x] make it work
  # [ ] make it right
  # [ ] make it fast
  post '/identities' do
    check_god_credentials(current_realm.id)

    @identity = create_identity(params['identity'], params['account'])
    render :rabl, :identity, :format => :json
  end

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

end
