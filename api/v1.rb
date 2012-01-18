# encoding: utf-8
require "json"
require 'pebblebed/sinatra'
require 'sinatra/petroglyph'

Dir.glob("#{File.dirname(__FILE__)}/v1/**/*.rb").each{ |file| require file }

class CheckpointV1 < Sinatra::Base
  set :root, "#{File.dirname(__FILE__)}/v1"
  set :show_exceptions, false

  register Sinatra::Pebblebed
  i_am :checkpoint

  error ActiveRecord::RecordNotFound do
    halt 404, "Record not found"
  end

  error Exception do |e|
    halt 500, e.message
  end

  helpers do 
    def current_session
      params[:session] || request.cookies[Session::COOKIE_NAME]
    end

    def current_identity
      return @current_identity if @current_identity
      @current_identity = Identity.find_by_session_key(current_session)
      @current_identity
    end

    def log_in(identity)
      return if current_identity == identity
      session = Session.create!(:identity => identity)
      response.set_cookie(Session::COOKIE_NAME, :value => session.key,
        :path => '/',
        :expires => Time.now + 1.year)
      @current_identity = identity
    end

    def log_out
      Session.destroy_by_key(current_session)
      response.delete_cookie(Session::COOKIE_NAME)
      @current_identity = nil      
    end

    def check_god_credentials(realm_id)
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
  end

  get '/ping' do
    failures = []

    begin
      ActiveRecord::Base.connection.execute("select 1")
    rescue Exception => e
      failures << "ActiveRecord: #{e.message}"
    end

    begin
      $memcached.get('ping')
    rescue Exception => e
      failures << "Memcached: #{e.message}"
    end

    if failures.empty?
      halt 200, "checkpoint"
    else
      halt 503, failures.join("\n")
    end
  end
end
