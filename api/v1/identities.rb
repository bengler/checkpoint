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

  # Create a new identity.
  #
  # @param [Hash] identity the attributes of the new identity
  # @param [Hash] account the attributes of the new account (optional)
  post '/identities' do
    check_god_credentials(current_realm.id)

    identity = create_identity(params['identity'], params['account'])
    pg :identity, :locals => {:identity => identity}
  end

  put '/identities/:id' do |id|
    check_god_credentials(current_realm.id)
    identity = Identity.cached_find_all_by_id([id]).first
    identity.update_attributes!(params[:identity])
    pg :identity, :locals => {:identity => identity}
  end

  # Retrieve one or more identities
  #
  # @param [String] id the id or a comma separated list of ids. One id with a trailing comma will return a list of one.
  # @return [JSON] The identity or identities.
  get '/identities/:id' do |id|
    if id =~ /\,/
      # Retrieve a list of identities      
      ids = id.split(/\s*,\s*/).compact
      identities = Identity.cached_find_all_by_id(ids)
      pg :identities, :locals => {:identities => identities}
    else
      # Retrieve a single identity
      identity = (id == 'me') ? current_identity : Identity.cached_find_by_id(id)
      halt 200, "{}" unless identity
      pg :identity, :locals => {:identity => identity}
    end
  end

end
