# encoding: utf-8
require "json"
require 'pebblebed/sinatra'
require 'sinatra/petroglyph'

Dir.glob("#{File.dirname(__FILE__)}/v1/**/*.rb").each{ |file| require file }

class CheckpointV1 < Sinatra::Base
  set :root, "#{File.dirname(__FILE__)}/v1"
  set :show_exceptions, false

  register Sinatra::Pebblebed

  error ActiveRecord::RecordNotFound do
    halt 404, "Record not found"
  end

  error Exception do |e|
    $logger.error e.message
    e.backtrace.each do |line|
      $logger.error line
    end
    halt 500, e.message
  end

  not_found do
    'Not found'
  end

  before do
    cache_control :private, :no_cache, :no_store, :must_revalidate
  end

  after do
    current_identity.mark_as_seen if current_identity
  end

  after do
    session = @current_session
    session.save! if @session_is_dirty

    # Delete legacy cookie on wrong domain
    Rack::Utils.parse_query(request.env['HTTP_COOKIE'], ';,').each do |k, v|
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

  helpers do
    # Is the current host the realm's primary domain?
    def on_primary_domain?
      current_realm && request.host == current_realm.primary_domain.name 
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

    def session_from_cookie
      if (key = current_session_key)
        session = Session.where("key = ?", key).first(:include => :identity)
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
      @session_is_dirty = true
      @session_cookie_is_dirty = true
      session
    end

    def set_session_key(key)
      @current_session = Session.find_by_key(key)
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
        @session_is_dirty = true
        @current_identity = identity
      end
    end

    def log_out
      if current_session.identity and not current_session.identity.provisional?
        current_session.identity = nil
        @session_is_dirty = true
      end
      @current_identity = nil      
    end

    def check_god_credentials(realm_id)
      unless realm_id
        halt 403, "Unknown realm"
      end
      unless current_identity.try(:god?) && current_identity.realm_id == realm_id
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
      halt 200, "{}" unless realm
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
      target_host = URI.parse(url).host
      if target_host.nil? || target_host == request.host
        # This can be solved with the common household redirect
        redirect url
      else
        # Use the transfer mechanism to redirect across domains
        redirect url_with_query_params("/api/checkpoint/v1/transfer", :target => url)
      end
    end

  end
end
