class CheckpointV1 < Sinatra::Base

  error Account::InUseError do |e|
    halt 409,
      {'Content-Type' => 'application/json'},
      {
        error: {
          message: e.message,
          identity: e.identity_id
        }
      }.to_json
  end

  helpers do
    def create_identity(identity_data, account_data)
      # ensure_account_unique(account_data)
      identity = nil
      Identity.transaction :requires_new => true do # Creates savepoint
        attributes = identity_data || {}
        identity = Identity.create! attributes.merge(:realm => current_realm)

        if account_data
          account_data[:identity] = identity
          Account.declare!(account_data)
        end
      end
      identity
    end

  end

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
    identity = Identity.find(id)
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
      halt 200, {'Content-Type' => 'application/json'}, "{}" unless identity
      pg :identity, :locals => {:identity => identity}
    end
  end

end
