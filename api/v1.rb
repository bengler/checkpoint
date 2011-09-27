# encoding: utf-8
require "json"

class CheckpointV1 < Sinatra::Base

  get '/' do
    <<-HTML
      <a href='/api/v1/auth/twitter'>Sign in with Twitter</a>
    HTML
  end

  get '/auth/failure' do
    request.inspect
  end

  get '/auth/:name/callback' do
    auth = request.env['omniauth.auth']
    # do whatever you want with the information!
    "oh look: #{auth.inspect}"
  end
end
