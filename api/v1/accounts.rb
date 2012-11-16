class CheckpointV1 < Sinatra::Base

  # Get all accounts for an identity. Requires god permissions or that the
  # identity is the same as the current session identity.
  get '/identities/:id/accounts' do |id|
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
  # @category Checkpoint/Idenities
  # @path /api/checkpoint/v1/identities/
  # @http GET
  # @example /api/checkpoint/v1/identities/1/accounts/facebook
  # @required [String] id the identity id. Can be a numeric id or the string 'me'.
  # @required [String] provider the provider of the account, e.g. 'github', 'twitter'.
  # @returns [JSON]
  get '/identities/:id/accounts/:provider' do |id, provider|
    identity = (id == 'me') ? current_identity : Identity.find(id)
    halt 404, "No such identity" unless identity
    check_god_credentials(identity.realm_id) unless identity == current_identity
    account = identity.accounts.where("provider = ?", params[:provider]).first
    halt 200, {'Content-Type' => 'application/json'}, "{}" unless account
    pg :account, :locals => {:account => account}
  end

  # Get an account by provider and uid. Requires god permissions or that the
  # given account is associated with the current session identity.
  #
  # @returns [JSON]
  get '/accounts/:provider/:uid' do |provider, uid|
    account = Account.where(
      :realm_id => current_identity.realm_id,
      :provider => provider,
      :uid => uid).first
    halt 404, "No such account" unless account
    check_god_credentials(current_identity.realm_id) unless current_identity == account.identity
    pg :account, :locals => {:account => account}
  end

  # Create or updates an account and associate with the current identity.
  # If there is no current identity, then a new identity is created, unless
  # `identity_id` is provided. Requires god permissions.
  #
  post '/identities/:id/accounts/:provider/:uid' do |id, provider, uid|
    check_god_credentials(current_identity.realm_id)
    transaction do
      identity = (id == 'me') ? current_identity : Identity.find(id)
      attributes = {
        :uid => uid,
        :identity => identity,
        :provider => provider
      }.merge(params.slice(
        *%w(token secret nickname
          name location description profile_url image_url email)))
      account = Account.declare!(attributes)
      # Was it created or updated?
      status = (account.created_at == account.updated_at) ? 201 : 200
      [status, pg(:account, :locals => {:account => account})]
    end
  end

  # Deletes an account. Requires god permissions.
  #
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
