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

  # @apidoc
  # Create a new identity.
  #
  # @note Only for gods. Check readme for details on the parameters.
  # @description Typically a new identity is created implicitly by logging in for the first
  #   time in a new realm. This endpoint is used for importing accounts from legacy systems.
  # @category Checkpoint/Identities
  # @path /api/checkpoint/v1/identities
  # @example /api/checkpoint/v1/identities
  # @http POST
  # @required [Hash] identity The attributes of the new identity.
  # @required [Hash] account The attributes of the default account.
  # @status 201 [JSON]

  post '/identities' do
    check_god_credentials(current_realm.id)

    identity = create_identity(params['identity'], params['account'])
    [201, pg(:identity, :locals => {:identity => identity})]
  end

  # @apidoc
  # Update attributes for an identity.
  #
  # @note Only for gods. Check readme for details on the parameters.
  # @category Checkpoint/Identities
  # @path /api/checkpoint/v1/identities/:id
  # @example /api/checkpoint/v1/identities/1337
  # @http POST
  # @required [Integer] id The id of the identity to update.
  # @required [Hash] identity The updated attributes.
  # @status 200 [JSON]

  put '/identities/:id' do |id|
    check_god_credentials(current_realm.id)
    identity = Identity.find(id)
    identity.update_attributes!(params[:identity])
    pg :identity, :locals => {:identity => identity}
  end


  # @apidoc
  # Find identities, match against attributes on the identities' accounts.
  #
  # @note Only for gods.
  # @category Checkpoint/Identities
  # @path /api/checkpoint/v1/identities/find
  # @example /api/checkpoint/v1/identities/find?q[nickname]=foo&q[name]=bar&operator=or
  # @http GET
  # @optional [String] q[nickname] Account nickname
  # @optional [String] q[name] Account name
  # @optional [String] q[provider] Account provider (lowercase keyword)
  # @optional [String] q[location] Account location
  # @optional [String] q[description] Account description
  # @optional [String] q[email] Account email
  # @optional [String] operator 'and' or 'or' kind of matching
  # @status 200 [JSON]

  get '/identities/find' do
    require_god
    check_god_credentials(current_realm.id)
    q = params[:q]
    pg :identities, :locals => {
        :identities => Identity.find_by_query(params[:q].symbolize_keys!, params[:operator])
      }
  end

  # @apidoc
  # Retrieve one or more identities including profiles.
  #
  # @category Checkpoint/Identities
  # @path /api/checkpoint/v1/identities/:id
  # @example /api/checkpoint/v1/identities/me
  # @http GET
  # @required [Integer] id The identity id or a comma-separated list of ids, 'me'
  #   for current user.
  # @status 200 [JSON]

  get '/identities/:id' do |id|
    if id =~ /\,/
      # Retrieve a list of identities
      ids = id.split(/\s*,\s*/).compact
      identities = Identity.cached_find_all_by_id(ids)
      pg :identities, :locals => {:identities => identities}
    else
      # Retrieve a single identity.
      identity = (id == 'me') ? current_identity : Identity.cached_find_by_id(id)
      halt 200, {'Content-Type' => 'application/json'}, "{}" unless identity
      pg :identity, :locals => {:identity => identity}
    end
  end

end
