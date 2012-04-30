class CheckpointV1 < Sinatra::Base

  def ensure_valid_redirect_path
    return nil unless params[:redirect_to]
    begin
      uri = URI(params[:redirect_to])
    rescue => e
      halt 500, "Malformed value for redirect_to: '#{params[:redirect_to]}'. Please specify a valid path (i.e. /path/to/landing-page)."
    end
    uri.host ||= request.host
    uri.scheme = "http"
    uri.to_s
  end

  helpers do
    # Will execute the provided block only if we are not on the primary domain
    def on_primary_domain?
      request.host == current_realm.primary_domain.name 
    end
  end

  # Log in anonymously
  #
  # @param [String] redirect_to where to redirect to
  get '/login/anonymous' do
    halt 500, "No registered realm for #{request.host}" unless current_realm
    redirect_to_path = ensure_valid_redirect_path || '/'
    anonymous_identity = Identity.find_by_session_key(current_session_key) || Identity.create!(:realm => current_realm)
    log_in(anonymous_identity)
    redirect redirect_to_path
  end

  # Log in with a given provider
  #
  # @param [String] provider which provider's login to redirect to
  # @param [String] redirect_to where to redirect to after login is complete (optional)
  get '/login/:provider' do
    halt 500, "No registered realm for #{request.host}" unless current_realm

    # Make sure the target url is fully qualified with domain
    target_url = URI.parse(params[:redirect_to] || "/login/succeeded")
    target_url.host ||= request.host
    target_url.scheme = "http"

    unless on_primary_domain?
      # Proceed on primary domain rewriting the current url

      url = URI.parse(request.url)
      url.host = current_realm.primary_domain.name
      url.query = "redirect_to=#{CGI.escape(target_url.to_s)}"
      redirect url.to_s
    else
      session[:redirect_to] = target_url.to_s
      redirect to("/auth/#{params[:provider]}")
    end
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
      redirect "http://#{URI.parse(session[:redirect_to]).host}/login/failed?message=account_in_use"
      return
    end

    transfer session[:redirect_to]
  end

  get '/auth/failure' do
    redirect "http://#{URI.parse(session[:redirect_to].host)}/login/failed?message=#{params[:message]}"
  end

  # Log out
  get '/logout' do
    halt 500, "Not allowed to log out provisional identity" if current_identity.try :provisional?
    log_out
    redirect request.referer
  end
end
