class CheckpointV1 < Sinatra::Base

  get '/login/:provider' do
    halt 404, "Unknown realm #{request.host}" unless current_realm
    session[:redirect_to] = params[:redirect_to] if params[:redirect_to]
    redirect to("/auth/#{params[:provider]}")
  end

  # This is called directly by Omniauth as a rack method
  # (not HTTP, mkay?) to allow us to setup
  # the strategy.
  #
  # Oh, and by the way:
  # OMNIAUTH SWALLOWS ALL HTTP ERRORS AND EXCEPTIONS.
  get '/auth/:provider/setup' do

    strategy = request.env['omniauth.strategy']
    service_keys = current_realm.keys_for(params[:provider].to_sym)

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

  get '/auth/:provider/callback' do
    return halt(500, "Realm not specified in session") unless current_realm

    begin
      account = Account.declare_with_omniauth(request.env['omniauth.auth'], :realm => current_realm, :identity => current_identity)
      set_current_identity(account.identity)
    rescue Account::InUseError => e
      redirect '/login/failed?message=account_in_use'
    end

    if session[:redirect_to]
      redirect session[:redirect_to]
    else
      redirect '/login/succeeded'
    end
  end

  get '/logout' do
    response.delete_cookie(SessionManager::COOKIE_NAME)
    redirect request.referer
  end
end
