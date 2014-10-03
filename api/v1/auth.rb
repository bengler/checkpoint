class CheckpointV1 < Sinatra::Amedia::Base

  def ensure_valid_redirect_path
    return nil unless params[:redirect_to]
    begin
      uri = URI(params[:redirect_to])
    rescue => e
      abort 500, "Malformed value for redirect_to: '#{params[:redirect_to]}'. Please specify a valid path (i.e. /path/to/landing-page).", e
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
      elsif params[:url]
        return_url = params[:url]
      elsif params[:path]
        return_url = "http://#{request.host}#{params[:path]}"
      else
        return_url = "http://#{request.host}/login/failed"
      end
      return url_with_params(return_url, params)
    end

    def get_request(url)
      uri = URI.parse(url)
      response = nil
      Net::HTTP.start(uri.host) do |http|
        response = http.get(uri.request_uri)
      end
      response
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
    abort 500, "No registered realm for #{request.host}" unless current_realm

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
    if request.xhr?
      halt 200, {status: "Logged in"}.to_json
    else
      redirect redirect_to_path
    end
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
    abort 500, "No registered realm for #{request.host}" unless current_realm

    # Make sure the target URL is fully qualified with domain.
    target_url = URI.parse(params[:redirect_to] || "/login/succeeded")
    target_url.host ||= request.host
    target_url.scheme ||= request.scheme

    session[:force_dialog] = params[:force_dialog].to_s == 'true'
    session[:display] = params[:display]

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

  post '/login/:provider' do
    strategy = Checkpoint.strategies.find {|s| s.supports? params[:provider] } or
      abort 400, "No strategy can handle the \"#{params[:provider]}\" provider"

    provider = strategy.get_provider(params[:provider])
    provider.mode == 'direct' or
      abort 400, 'Requested provider does not support the direct authentication mode'

    params[:failure_url] or
      abort 400, 'Missing required parameter: failure_url'

    attributes = begin
      provider.authenticate(params)
    rescue Checkpoint::Strategy::InvalidCredentialsError => ex
      logger.info "Login failed due to invalid credentials: #{ex.message}"
      url_or_path = (params[:failure_url][0] == '/' ? :path : :url)
      redirect url_for_failure({:message => :invalid_credentials,
        :text => ex.message, url_or_path => params[:failure_url]})
    end

    attributes[:realm_id] = current_realm.id
    account = begin
      Account.declare!(attributes)
    rescue Account::InUseError => ex
      user_id = attributes[:uid]
      logger.info("Login failed due to account being in use for user_id=#{user_id}: #{ex.message}",
        user_id: user_id)
      url_or_path = (params[:failure_url][0] == '/' ? :path : :url)
      redirect url_for_failure({:message => :account_in_use,
        :text => ex.message, url_or_path => params[:failure_url]})
    end

    log_in(account.identity)
    logger.info("Logged successful through #{params[:provider]} as user_id=#{account.uid}.",
      user_id: account.uid)

    unless request.xhr?
      # Make sure the target URL is fully qualified with domain.
      target_url = URI.parse(params[:redirect_to] || '/login/succeeded')
      target_url.host ||= request.host
      target_url.scheme ||= request.scheme
      target_url.query ||= ''
      target_url.query += "session=#{current_session.key}"
      response = get_request(target_url.to_s)
      content_type response.content_type
      halt response.code.to_i, response.body
    end
  end

  # This is called directly by Omniauth as a rack method.
  # OMNIAUTH SWALLOWS ALL HTTP ERRORS AND EXCEPTIONS.
  get '/auth/:provider/setup' do

    strategy = request.env['omniauth.strategy']

    service_keys = current_realm.keys_for(params[:provider].to_sym)

    strategy.options[:force_dialog] = session[:force_dialog]
    strategy.options[:display] = session[:display] if params[:provider] == 'facebook'
    strategy.options[:target_url] = session[:redirect_to]

    if strategy.options.respond_to?(:consumer_key)
      strategy.options.consumer_key = service_keys.consumer_key
      strategy.options.consumer_secret = service_keys.consumer_secret
    elsif strategy.options.respond_to?(:client_id)
      strategy.options.client_id = service_keys.client_id
      strategy.options.client_secret = service_keys.client_secret
    else
      abort 500, "Invalid strategy for provider: #{params[:provider]}"
    end
    strategy.options[:scope] = service_keys.scope if service_keys.scope
    strategy.options[:client_options].site = service_keys.site if service_keys.site
  end

  get '/auth/:provider/callback' do
    abort 500, "No registered realm for #{request.host}" unless current_realm

    begin
      account = Account.declare_with_omniauth!(request.env['omniauth.auth'], current_realm)
      log_in(account.identity)
    rescue Account::InUseError => e
      redirect url_for_failure(:message => :account_in_use)
      return
    end

    if (url = session[:redirect_to])
      transfer(url)
    else
      abort 500, "Your browser has issues with cookies, which are required to log in."
    end
  end

  get '/auth/failure' do
    redirect url_for_failure(:message => params[:message] || 'unknown')
  end

  # FIXME: Should not offer this as GET.
  get '/logout' do
    abort 500, "Not allowed to log out provisional identity" if current_identity.try :provisional?
    if current_identity && current_identity.primary_account
      user_id = current_identity.primary_account.uid
    end
    log_out
    logger.info "Logged out identity with primary account user_id=#{user_id}", user_id: user_id
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
    abort 500, "Not allowed to log out provisional identity" if current_identity.try :provisional?
    if current_identity && current_identity.primary_account
      user_id = current_identity.primary_account.uid
    end
    log_out
    logger.info "Logged out identity with primary account user_id=#{user_id}", user_id: user_id
    halt 200, {status: "Logged out"}.to_json if request.xhr?
    redirect params[:redirect_to] || request.referer
  end

end
