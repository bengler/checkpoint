class CheckpointV1 < Sinatra::Base

  get '/:realm/auth/:provider' do
    realm = Realm.find_by_label(params[:realm])
    halt 404, "Unknown realm #{params[:realm]}" unless realm
    session[:realm] = params[:realm]
    redirect to("/auth/#{params[:provider]}")
  end

  # This is called directly by Omniauth as a rack method
  # (not HTTP, mkay?) to allow us to setup
  # the strategy. Unfortunately I did not find a way to
  # provide the realm with the url, so it is passed through
  # the session. Yuck!
  #
  # Oh, and by the way:
  # OMNIAUTH SWALLOWS ALL HTTP ERRORS AND EXCEPTIONS.
  get '/auth/:provider/setup' do
    strategy = request.env['omniauth.strategy']
    realm = Realm.find_by_label(session[:realm])
    service_keys = realm.keys_for(params[:provider].to_sym)

    if strategy.respond_to?(:consumer_key)
      strategy.consumer_key = service_keys.consumer_key
      strategy.consumer_secret = service_keys.consumer_secret
    elsif strategy.respond_to?(:client_id)
      strategy.client_id = service_keys.client_id
      strategy.client_secret = service_keys.client_secret
    else
      halt 500, "Invalid strategy for provider: #{params[:provider]}"
    end

    strategy.options[:scope] = service_keys.scope if service_keys.scope

    # TODO: Add detection of device to wisely choose whether we should ask for
    # touch interface from facebook.
    # strategy.options[:display] = "touch" if params[:provider] == "facebook"

    "Setup complete."
  end

  get "/auth/:provider/terminate" do
    # TODO: Find realm through authentication
    realm = Realm.find_by_label(params[:realm])

    auth = current_identity.accounts.where(
      :realm_id => realm.id, :provider => params[:provider])
      return halt 404, "No such authentication found" if auth.empty?
      auth.map(&:destroy)

      logger.info("Terminated #{params[:provider]} authentication for identity #{current_identity.id} in realm #{realm.label}.")

      "Authorization for provider #{params[:provider]} terminated."
  end


  get '/auth/:provider/callback' do
    realm = Realm.find_by_label(session[:realm])
    return halt(500, "Realm not specified in session") unless realm
    # TODO: Session!
    account = Account.declare_with_omniauth(request.env['omniauth.auth'], :realm => realm)
    "realm: #{realm.label}! oh look: #{request.env['omniauth.auth'].inspect}"
  end
end
