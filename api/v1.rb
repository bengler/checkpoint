# encoding: utf-8
require "json"

Dir.glob("#{File.dirname(__FILE__)}/v1/**").each{ |file| require file }

class CheckpointV1 < Sinatra::Base
  before do
    Thread.current[:identity] = nil
  end

  helpers do 
    def current_identity
      return Thread.current[:identity] if Thread.current[:identity] 
      identity_id = SessionManager.identity_id_for_session(request.cookies[SessionManager::COOKIE_NAME])
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
  end

  get '/' do
    <<-HTML
      <a href='/api/v1/area51/auth/twitter'>Sign in with Twitter</a>
    HTML
  end
end
