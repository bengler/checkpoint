class CheckpointV1 < Sinatra::Base

  get '/login/:provider' do
    halt 500, "No registered realm for #{request.host}" unless current_realm
    session[:redirect_to] = params[:redirect_to] if params[:redirect_to]
    redirect to("/auth/#{params[:provider]}")
  end

  # This is called directly by Omniauth as a rack method
  # OMNIAUTH SWALLOWS ALL HTTP ERRORS AND EXCEPTIONS.
  get '/auth/:provider/setup' do

    strategy = request.env['omniauth.strategy']
    service_keys = current_realm.keys_for(params[:provider].to_sym)

    if strategy.options.respond_to?(:consumer_key)
      strategy.options.consumer_key = service_keys.consumer_key
      strategy.options.consumer_secret = service_keys.consumer_secret
    elsif strategy.options.respond_to?(:client_id)
      strategy.options.client_id = service_keys.client_id
      strategy.options.client_secret = service_keys.client_secret
    else
      halt 500, "Invalid strategy for provider: #{params[:provider]}"
    end
    strategy.options[:scope] = service_keys.scope if service_keys.scope

    # TODO: Add detection of device to wisely choose whether we should ask for
    # touch interface from facebook.
    # strategy.options[:display] = "touch" if params[:provider] == "facebook"
  end

  get '/auth/:provider/callback' do
    halt 500, "No registered realm for #{request.host}" unless current_realm

    begin
      account = Account.declare_with_omniauth(request.env['omniauth.auth'], :realm => current_realm, :identity => current_identity)
      log_in(account.identity)
    rescue Account::InUseError => e
      redirect '/login/failed?message=account_in_use'
    end

    redirect session[:redirect_to] || '/login/succeeded'
  end

  get '/auth/failure' do
    redirect "/login/failed?message=#{params[:message]}"
  end

  get '/logout' do
    log_out
    redirect request.referer
  end
end
