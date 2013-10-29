class CheckpointV1 < Sinatra::Base

  # @apidoc
  # Get all accounts for an identity. Requires god permissions or that the
  # identity is the same as the current session identity.
  #
  # @note Only provided to the identity in question or god.
  # @category Checkpoint/Accounts
  # @path /api/checkpoint/v1/identities/:id/accounts
  # @http GET
  # @example /api/checkpoint/v1/identities/1337/accounts
  # @required [String] id The id of the identity. ('me' for current identity).
  # @status 404 No such identity.
  # @status 403 This is not you or you are not god!
  get '/identities/:id/accounts' do |id|
    require_identity
    if id == 'me'
      @identity = current_identity
    else
      @identity = Identity.find(id)
    end
    halt 404, "No such identity" unless @identity
    check_god_credentials(current_identity.realm_id) unless @identity == current_identity
    pg :accounts, :locals => {:accounts => @identity.accounts}
  end

  # @apidoc
  # Get an account for an identity. Requires god permissions or that the identity
  # is the current session identity.
  #
  # @note Only provided to the identity in question or god.
  # @category Checkpoint/Accounts
  # @path /api/checkpoint/v1/identities/:id/accounts/:provider
  # @http GET
  # @example /api/checkpoint/v1/identities/1/accounts/facebook
  # @required [String] id The identity id. Can be a numeric id or the string 'me'.
  # @required [String] provider The provider of the account, e.g. 'github', 'twitter', 'facebook'.
  # @status 200 [JSON]
  # @status 404 No such identity.
  get '/identities/:id/accounts/:provider' do |id, provider|
    identity = (id == 'me') ? current_identity : Identity.find(id)
    halt 404, "No such identity" unless identity
    check_god_credentials(identity.realm_id) unless identity == current_identity
    account = identity.accounts.where("provider = ?", params[:provider]).first
    halt 200, {'Content-Type' => 'application/json'}, "{}" unless account
    pg :account, :locals => {:account => account}
  end

  # @apidoc
  # Get an account by provider and uid. Requires god permissions or that the
  # given account is associated with the current session identity.
  #
  # @note Only provided to god-identities.
  #
  # @category Checkpoint/Accounts
  # @path /api/checkpoint/v1/accounts/:provider/:uid
  # @http GET
  # @example /api/checkpoint/v1/accounts/twitter/12312
  # @required [String] provider The provider of the account. E.g. github, twitter, facebook.
  # @required [String] uid The id of the account according to the provider.
  # @status 200 [JSON]
  # @status 404 No such account.
  get '/accounts/:provider/:uid' do |provider, uid|
    account = Account.where(
      :realm_id => current_identity.realm_id,
      :provider => provider,
      :uid => uid).first
    halt 404, "No such account" unless account
    check_god_credentials(current_identity.realm_id) unless current_identity == account.identity
    pg :account, :locals => {:account => account}
  end

  # @apidoc
  # Create or updates an account and associate with an identity.
  # If there is no current identity, then a new identity is created, unless
  # `identity_id` is provided. Requires god permissions.
  #
  # @category Checkpoint/Accounts
  # @path /api/checkpoint/v1/identities/:id/accounts/:provider/:uid
  # @http POST
  # @example /api/checkpoint/v1/identities/1/accounts/twitter/1231241
  # @required [String] provider The provider of the account. E.g. github, twitter, facebook.
  # @required [String] uid The id of the account according to the provider.
  # @required [JSON] account The account record (see readme).
  # @status 201 [JSON]
  # @status 404 No such identity.
  post '/identities/:id/accounts/:provider/:uid' do |id, provider, uid|
    check_god_credentials(current_identity.realm_id)
    transaction do
      identity = (id == 'me') ? current_identity : Identity.find(id)
      attributes = {
        :uid => uid,
        :identity => identity,
        :provider => provider,
        :realm_id => current_identity.realm_id
      }.merge(params.slice(
        *%w(token secret nickname
          name location description profile_url image_url email)))
      account = Account.declare!(attributes)
      [crud_http_status(account), pg(:account, :locals => {:account => account})]
    end
  end

  # @apidoc
  # Deletes an account. Requires god permissions.
  #
  # @note Only for gods and self.
  #
  # @category Checkpoint/Accounts
  # @path /api/checkpoint/v1/identities/:id/accounts/:provider/:uid
  # @http DELETE
  # @example /api/checkpoint/v1/identities/1/accounts/twitter/1231241
  # @required [String] provider The provider of the account. E.g. github, twitter, facebook.
  # @required [String] uid The id of the account according to the provider.
  # @status 204 Gone.
  # @status 404 No such identity.
  delete '/identities/:id/accounts/:provider/:uid' do |id, provider, uid|
    check_god_credentials(current_identity.try(:realm_id))
    transaction do
      identity = (id == 'me') ? current_identity : Identity.find(id)
      account = identity.accounts.where(:provider => provider, :uid => uid).first
      halt 404, "No such account" unless account
      account.destroy
      halt 204
    end
  end

end
