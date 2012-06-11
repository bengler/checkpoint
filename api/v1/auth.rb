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
    def url_with_params(url, params)
      uri = URI.parse(self.url(url))
      
      query = CGI.parse(uri.query || '')
      query = HashWithIndifferentAccess[*query.entries.map { |k, v| [k, v[0]] }.flatten]
      query.merge!(params)

      uri.query = QueryParams.encode(query)
      uri.to_s
    end

    def url_for_failure(params = {})
      params = {:status => 'failed'}.merge(params)
      if (return_url = session[:redirect_to])
        if return_url =~ /_completion/
          # FIXME: Exception for Origo. This is supposed to be the correct behaviour,
          #   but we do this to avoid breaking existing apps.
          return url_with_params(return_url, params)
        end
        host = URI.parse(return_url).host
      else
        host = request.host
      end
      return url_with_params("http://#{host}/login/failed", params)
    end
  end

  # Log in anonymously
  #
  # @param [String] redirect_to where to redirect to
  get '/login/anonymous' do
    halt 500, "No registered realm for #{request.host}" unless current_realm
    
    anonymous_identity = Identity.find_by_session_key(current_session_key) 

    # If this ip is hot, we need to perform a captcha-test first
    if !anonymous_identity && IdentityIp.hot?(request_ip) && !passed_captcha?
      redirect url_with_params("/auth/captcha", :continue_to => request.url)
      return
    end
    clear_captcha!

    redirect_to_path = ensure_valid_redirect_path || '/'
    anonymous_identity ||= Identity.create!(:realm => current_realm)
    log_in(anonymous_identity)
    redirect redirect_to_path
  end

  # Log in with a given provider
  #
  # @param [String] provider which provider's login to redirect to
  # @param [String] redirect_to where to redirect to after login is complete (optional)
  get '/login/:provider' do
    halt 500, "No registered realm for #{request.host}" unless current_realm

    # Make sure the target URL is fully qualified with domain
    target_url = URI.parse(params[:redirect_to] || "/login/succeeded")
    target_url.host ||= request.host
    target_url.scheme ||= "http"

    session[:force_dialog] = params[:force_dialog].to_s == 'true'

    if on_primary_domain?
      session[:redirect_to] = target_url.to_s
      redirect to("/auth/#{params[:provider]}")
    else
      # Proceed on primary domain rewriting the current URL
      uri = URI.parse(request.url)
      uri.host = current_realm.primary_domain.name
      redirect url_with_query_params(uri.to_s,
        :redirect_to => target_url)
    end
  end

  # This is called directly by Omniauth as a rack method
  # OMNIAUTH SWALLOWS ALL HTTP ERRORS AND EXCEPTIONS.
  get '/auth/:provider/setup' do

    strategy = request.env['omniauth.strategy']

    service_keys = Realm.environment_specific_service_keys_for(current_realm.label, params[:provider])
    service_keys = current_realm.keys_for(params[:provider].to_sym)

    strategy.options[:force_dialog] = session[:force_dialog]

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
      account = Account.declare_with_omniauth(request.env['omniauth.auth'], :realm => current_realm)
      log_in(account.identity)
    rescue Account::InUseError => e
      redirect url_for_failure(:message => :account_in_use)
      return
    end

    transfer session[:redirect_to]
  end

  get '/auth/failure' do
    redirect url_for_failure(:message => params[:message] || 'unknown')
  end

  # FIXME: Should not offer this as GET.
  get '/logout' do
    halt 500, "Not allowed to log out provisional identity" if current_identity.try :provisional?
    log_out
    redirect params[:redirect_to] || request.referer
  end

  post '/logout' do
    halt 500, "Not allowed to log out provisional identity" if current_identity.try :provisional?
    log_out
    redirect params[:redirect_to] || request.referer
  end

end
