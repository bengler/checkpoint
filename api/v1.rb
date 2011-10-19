# encoding: utf-8
require "json"

Dir.glob("#{File.dirname(__FILE__)}/v1/**/*.rb").each{ |file| require file }

class CheckpointV1 < Sinatra::Base
  Rabl.register!

  after do
    Thread.current[:identity] = nil
  end

  helpers do 
    def current_identity
      return Thread.current[:identity] if Thread.current[:identity] 
      identity_id = SessionManager.identity_id_for_session(params[:session] || request.cookies[SessionManager::COOKIE_NAME])
      Thread.current[:identity] = Identity.find_by_id(identity_id)
    end

    def set_current_identity(identity)
      return if current_identity == identity
      key = SessionManager.new_session(identity.id)
      response.set_cookie(SessionManager::COOKIE_NAME, :value => key,
        :path => '/',
        :expires => Time.now + 1.year)
      Thread.current[:identity] = identity
    end

    def check_god_credentials(realm_id)
      unless current_identity.try(:god?) && current_identity.realm_id == realm_id
        halt 403, "You must be a god of the '#{Realm.find_by_id(realm_id).try(:label) || '[deleted]'}'-realm"
      end
    end
  end

end
