class CheckpointV1 < Sinatra::Base

  def ensure_valid_redirect_path
    return nil unless params[:redirect_to]
    begin
      uri = URI(params[:redirect_to])
    rescue => e
      halt 500, "Malformed value for redirect_to: '#{params[:redirect_to]}'. Please specify a valid path (i.e. /path/to/landing-page)."
    end
    uri.host ||= request.host
    uri.scheme ||= request.scheme
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

  # @apidoc
  # Log in anonymously.
  #
  # @note If a large number of anonymous identities have been created from a single ip-address
  #   the user will be asked to solve a captcha.
  #
  # @description Some applications require the user to perform actions that need an identity,
  #   but still do not require any authenitcation. Redirect the users browser here to get an
  #   anonymous user session. The identity will be a valid checkpoint identity with no accounts
  #   or profile.
  #
  # @category Checkpoint/Auth
  # @path /api/checkpoint/v1/login/anonymous
  # @http GET
  # @optional [String] redirect_to Where to redirect the user after login (NOTE: required if non-xhr request).
  # @status 301 Redirect to target address.
  # @status 200 (if xhr request) Logged in
  # @status 403 (if xhr request) IP-address is hot. Please redirect user to 'login/anonymous'
  # @status 409 (if xhr request) Logged in already

  get '/login/anonymous' do
    halt 500, "No registered realm for #{request.host}" unless current_realm

    anonymous_identity = Identity.find_by_session_key(current_session_key)

    # If this ip is hot we need to perform a captcha-test first.
    if !anonymous_identity && IdentityIp.hot?(request_ip) && !passed_captcha?
      return halt 403, "IP-address is hot. Please redirect user to location 'login/anonymous'" if request.xhr?
      return redirect url_with_params("/auth/captcha", :continue_to => request.url)
    end
    clear_captcha!
    return halt 409, "Logged in already" if current_identity and request.xhr?
    redirect_to_path = ensure_valid_redirect_path || '/'
    anonymous_identity ||= Identity.create!(:realm => current_realm)
    log_in(anonymous_identity)
    return 200, "Logged in" if request.xhr?
    redirect redirect_to_path
  end

  # @apidoc
  # Log in with a given provider.
  #
  # @description When a user wants to log in to your application, direct her
  #   to this endpoint. Checkpoint will take care of the authentication process
  #   and redirect the user to the target address with a valid session.
  #
  # @category Checkpoint/Auth
  # @path /api/checkpoint/v1/login/:provider
  # @http GET
  # @required [String] provider The provider to log in via. E.g. twitter, facebook, google.
  # @required [String] redirect_to Where to redirect the user after login.
  # @optional [Boolean] force_dialog Force login dialog with the provider (not supported by all providers).
  # @status 301 Redirect to target address.

  get '/login/:provider' do
    halt 500, "No registered realm for #{request.host}" unless current_realm

    # Make sure the target URL is fully qualified with domain.
    target_url = URI.parse(params[:redirect_to] || "/login/succeeded")
    target_url.host ||= request.host
    target_url.scheme ||= request.scheme

    session[:force_dialog] = params[:force_dialog].to_s == 'true'

    if on_primary_domain?
      session[:redirect_to] = target_url.to_s
      redirect to("/auth/#{params[:provider]}")
    else
      # Proceed on primary domain rewriting the current URL.
      uri = URI.parse(request.url)
      uri.host = current_realm.primary_domain_name
      redirect url_with_query_params(uri.to_s,
        :redirect_to => target_url)
    end
  end

  # This is called directly by Omniauth as a rack method.
  # OMNIAUTH SWALLOWS ALL HTTP ERRORS AND EXCEPTIONS.
  get '/auth/:provider/setup' do

    strategy = request.env['omniauth.strategy']

    service_keys = current_realm.keys_for(params[:provider].to_sym)

    strategy.options[:force_dialog] = session[:force_dialog]
    strategy.options[:target_url] = session[:redirect_to]

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

  # @apidoc
  # Log out from current session.
  #
  # @description Link to this endpoint to provide a way for the user to log out.
  #
  # @category Checkpoint/Auth
  # @path /api/checkpoint/v1/logout
  # @http POST
  # @required [String] redirect_to Where to redirect the user after login.
  # @status 301 Redirect to target address.

  post '/logout' do
    halt 500, "Not allowed to log out provisional identity" if current_identity.try :provisional?
    log_out
    redirect params[:redirect_to] || request.referer
  end

end
