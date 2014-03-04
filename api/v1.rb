# encoding: utf-8
require "json"
require 'pebblebed/sinatra'
require 'sinatra/petroglyph'

Dir.glob("#{File.dirname(__FILE__)}/v1/**/*.rb").each{ |file| require file }

class CheckpointV1 < Sinatra::Amedia::Base

  def self.api_path
    '/api/checkpoint/v1'
  end

  set :root, "#{File.dirname(__FILE__)}/v1"
  set :protection, :except => :http_origin

  configure :production do |config|
    config.set :show_exceptions, false
  end

  register Sinatra::Pebblebed
  register Sinatra::Restful

  error ActiveRecord::RecordNotFound do
    halt 404, "Record not found"
  end
  error ActiveRecord::UnknownAttributeError do |e|
    raise e unless request.post? or request.put?
    halt 400, "Invalid attribute: #{e.name || e.message}"
  end

  error Sinatra::NotFound do
    'Not found'
  end

  before do
    # If this service, for some reason, lives behind a proxy that rewrites the Cache-Control headers into
    # "must-revalidate" (which IE9, and possibly other IEs, does not respect), these two headers should properly prevent
    # caching in IE (see http://support.microsoft.com/kb/234067)
    headers 'Pragma' => 'no-cache'
    headers 'Expires' => '-1'

    @disable_caching = true # Tell sinatra-restful to disable caching

    # IE compatibility to allow cookies to be saved across domains
    headers('P3P' => 'CP="DSP IDC CUR ADM DELi STP NAV COM UNI INT PHY DEM"')
  end

  after do
    current_identity.mark_as_seen if current_identity
    log_ip
  end

  after do
    if (session = @current_session)
      # Sessions that are never assigned an identity will not be persisted
      session.save! if session.should_be_persisted?

      # Delete legacy cookie on wrong domain
      cookies = Rack::Utils.parse_query(request.env['HTTP_COOKIE'], ';,') { |s| Rack::Utils.unescape(s) rescue s }
      cookies.each do |k, v|
        if k == Session::COOKIE_NAME and v.is_a?(Array)
          response.set_cookie(Session::COOKIE_NAME,
            :value => '',
            :domain => ".#{request.host}",
            :path => '/',
            :expires => Time.now)
          @session_cookie_is_dirty = true
        end
      end

      if @session_cookie_is_dirty
        if on_primary_domain?
          expiry = Session::DEFAULT_EXPIRY.dup
        else
          # Use browser session cookie on secondary domains. This lets us control
          # the session's lifetime using the primary domain's cookie.
          expiry = nil
        end
        response.set_cookie(Session::COOKIE_NAME,
          :value => session.key,
          :path => '/',
          :expires => expiry)
      end
    end
  end

  helpers do
    def logger
      LOGGER
    end

    # Is the current host the realm's primary domain?
    def on_primary_domain?
      current_realm && (request.host == current_realm.primary_domain_name ||
                        Amedia::Properties.publications_service.get_production_hostname(request.host) == current_realm.primary_domain_name)
    end

    def current_session_key
      params[:session] || request.cookies[Session::COOKIE_NAME]
    end

    def current_session
      return @current_session ||= session_from_cookie || new_session
    end

    def ensure_session
      current_session  # Forces a session
    end

    # Determine the current request ip
    def request_ip
      ip = request.env['HTTP_X_FORWARDED_FOR'] || request.ip
      ip = ip.sub("::ffff:", "") # strip away ipv6 compatible formatting
      ip
    end

    # Logs the current ip and identity_id to help with fraud detection
    def log_ip
      IdentityIp.declare!(request_ip, current_identity.id) if current_identity
    end

    def session_from_cookie
      if (key = current_session_key)
        session = Session.where(:key => key).first(:include => :identity)
        session ||= Session.new(:key => key) if key
        unless session
          # Cookie contains invalid key, so delete cookie
          response.delete_cookie(Session::COOKIE_NAME)
        end
      end
      session
    end

    def new_session
      session = Session.new(:identity => @current_identity)
      @session_cookie_is_dirty = true
      session
    end

    def set_session_key(key)
      @current_session = Session.find_by_key(key)
      @current_session ||= Session.new(:key => key, :identity => @current_identity)
      if @current_session
        @session_cookie_is_dirty = true
        key
      end
    end

    def current_identity
      return @current_identity ||= current_session.identity
    end

    def transaction(&block)
      ActiveRecord::Base.transaction(&block)
    end

    def log_in(identity)
      if current_identity != identity
        current_session.identity = identity
        @current_identity = identity
      end
    end

    def log_out
      if (identity = current_session.identity)
        unless identity.provisional?
          current_session.identity = nil
        end
      end
      @current_identity = nil
      response.delete_cookie(Session::COOKIE_NAME)
    end

    def check_god_credentials(realm_id = current_realm.try(:id))
      unless realm_id
        halt 403, "Unknown realm"
      end
      on_same_realm = current_identity.try(:realm_id) == realm_id
      return if current_identity.try(:root?)
      unless current_identity.try(:god?) and on_same_realm
        halt 403, "You must be a god of the '#{Realm.find_by_id(realm_id).label}'-realm"
      end
    end

    def check_root_credentials
      unless current_identity && current_identity.root?
        halt 403, "You must be a god of the root realm"
      end
    end

    def current_realm
      @current_realm ||= Realm.find_by_url(request.host)
    end

    def find_realm_by_label(label)
      realm = current_realm if label == 'current'
      realm ||= Realm.find_by_label(label)
      halt 200, {'Content-Type' => 'application/json'}, "{}" unless realm
      realm
    end

    def url_with_query_params(url, params)
      uri = URI.parse(url)
      uri.query << "&" if uri.query
      uri.query ||= ''
      uri.query += QueryParams.encode(params)
      uri.to_s
    end

    # A redirect that can redirect across domains while maintaining the current session
    def transfer(url)
      logger.info "Transfer to #{url.inspect}"
      target_host = URI.parse(url).host
      if target_host.nil? || target_host == request.host
        # This can be solved with the common household redirect
        redirect url
      else
        # Use the transfer mechanism to redirect across domains
        redirect url_with_query_params("#{CheckpointV1.api_path}/transfer", :target => url)
      end
    end

    def redirect_with_logging(url)
      logger.info "Redirecting to #{url}"
      redirect_without_logging(url)
    end
    alias_method_chain :redirect, :logging

    # Returns 201 if object was created, otherwise 200.
    def crud_http_status(object)
      if object.created_at == object.updated_at and object.previous_changes.include?(:created_at)
        201
      else
        200
      end
    end
  end
end
