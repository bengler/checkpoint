# encoding: utf-8
require "json"
require 'pebblebed/sinatra'

Dir.glob("#{File.dirname(__FILE__)}/v1/**/*.rb").each{ |file| require file }

class CheckpointV1 < Sinatra::Base
  set :root, "#{File.dirname(__FILE__)}/v1"

  register Sinatra::Pebblebed
  i_am :checkpoint

  Rabl.register!

  error ActiveRecord::RecordNotFound do
    halt 404, "Record not found"
  end

  helpers do 
    def current_session
      params[:session] || request.cookies[Session::COOKIE_NAME]
    end

    def current_identity
      return @current_identity if @current_identity
      @current_identity = Identity.find_by_session_key(current_session)
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

  end

end
