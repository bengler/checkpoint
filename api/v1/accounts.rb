class CheckpointV1 < Sinatra::Base

  # Get all accounts for an identity.
  get '/identities/:id/accounts' do |id|
    if id == 'me'
      @identity = current_identity
    else
      @identity = Identity.find(id)
    end
    halt 404, "No such identity" unless @identity
    pg :accounts, :locals => {:accounts => @identity.accounts}
  end

  # Get an account for an identity
  #
  # @param [String] id the identity id. Can be a numeric id or the string 'me'
  # @param [String] provider the provider of the account, e.g. github, twitter
  # @returns [JSON]
  get '/identities/:id/accounts/:provider' do |id, provider|
    identity = (id == 'me') ? current_identity : Identity.find(id)
    halt 404, "No such identity" unless identity
    identity == current_identity or check_god_credentials(identity.realm_id)
    account = identity.accounts.where("provider = ?", params[:provider]).first
    halt 200, "{}" unless account.try(:authorized?)
    pg :account, :locals => {:account => account}
  end

  # Get an account by provider and uid. Only provided to god-identities.
  #
  # @returns [JSON]
  get '/accounts/:provider/:uid' do |provider, uid|
    check_god_credentials(current_identity.realm_id)
    account = Account.where(
      :realm_id => current_identity.realm_id,
      :provider => provider,
      :uid => uid).first
    halt 404, "No such account" unless account
    pg :account, :locals => {:account => account}
  end

  # Create an account and associate with the current identity. If there is
  # no current identity, then a new identity is created, unless
  # `identity_id` is provided.
  #
  put '/accounts/:provider/:uid' do |provider, uid|
    transaction do
      account = Account.where(
        :realm_id => current_identity.realm_id,
        :provider => provider,
        :uid => uid).first
      if account
        # Account exists, we will be updating it
        unless account.identity == current_identity
          check_god_credentials(current_identity.realm_id)
        end
      else
        # New account, find an identity to assign it to
        if (identity_id = params[:identity_id])
          identity = Identity.where(:id => identity_id).first
          halt 400, 'Identity not found' unless identity
          unless identity == current_identity
            check_god_credentials(current_identity.realm_id)
          end
        else
          identity = current_identity
          identity ||= Identity.new(:realm_id => current_realm.id)
        end
        account = Account.new(
          :realm_id => current_realm.id,
          :provider => provider,
          :uid => uid,
          :identity => identity)
      end
      account.attributes = params.slice(
        *%w(token secret nickname
          name location description profile_url image_url email))
      account.save!

      [201, pg(:account, :locals => {:account => account})]
    end
  end

  # Updates an account.
  #
  post '/accounts/:provider/:uid' do |provider, uid|
    transaction do
      account = Account.where(
        :realm_id => current_identity.realm_id,
        :provider => provider,
        :uid => uid).first
      halt 404, "No such account" unless account
      account.attributes = params.slice(
        %w(token secret nickname
          name location description profile_url image_url email))
      account.save!
      
      [201, pg(:account, :locals => {:account => account})]
    end
  end

  # Deletes an account.
  #
  delete '/accounts/:provider/:uid' do |provider, uid|
    transaction do
      account = Account.where(
        :realm_id => current_identity.realm_id,
        :provider => provider,
        :uid => uid).first
      halt 404, "No such account" unless account
      account.destroy
      halt 200
    end
  end

end
