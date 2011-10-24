# encoding: utf-8
require "json"

Dir.glob("#{File.dirname(__FILE__)}/v1/**/*.rb").each{ |file| require file }

class CheckpointV1 < Sinatra::Base
  Rabl.register!

  helpers do 
    def current_session
      params[:session] || request.cookies[SessionManager::COOKIE_NAME]
    end

    def current_identity
      return @current_identity if @current_identity
      @current_identity = Identity.find_by_id(SessionManager.identity_id_for_session(current_session))
    end

    def log_in(identity)
      return if current_identity == identity
      key = SessionManager.new_session(identity.id)
      response.set_cookie(SessionManager::COOKIE_NAME, :value => key,
        :path => '/',
        :expires => Time.now + 1.year)
      @current_identity = identity
    end

    def check_god_credentials(realm_id)
      unless current_identity.try(:god?) && current_identity.realm_id == realm_id
        halt 403, "You must be a god of the '#{Realm.find_by_id(realm_id).try(:label) || '[deleted]'}'-realm"
      end
    end

    def current_realm
      @current_realm ||= Realm.find_by_url(request.host)
    end

  end

end
