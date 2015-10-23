$:.unshift(File.dirname(__FILE__))

require 'config/environment'
require 'api/v1'
require 'rack/contrib'

ENV['RACK_ENV'] ||= 'development'
set :environment, ENV['RACK_ENV'].to_sym

map "/api/checkpoint/v1" do

  session_secret = (YAML.load(File.open('./config/session-secret.yml', 'r:utf-8')) || {}).fetch(ENV['RACK_ENV'], {})["secret"]
  use Rack::PostBodyContentTypeParser
  use Rack::MethodOverride
  use Rack::Session::Cookie, :key => 'checkpoint.cookie', :secret => session_secret

  use OmniAuth::Builder do
    provider :twitter, nil, nil, :setup => true
    provider :facebook, nil, :setup => true
    provider :origo, nil, nil, :setup => true
    provider :vanilla, nil, nil, :setup => true
    #provider :openid, nil, :name => 'google', :identifier => 'https://www.google.com/accounts/o8/id'
    provider :google_oauth2, nil, nil, :setup => true
    provider :evernote, nil, nil, :setup => true

    on_failure do |env|
      message_key = env['omniauth.error.type'] # Generic omniauth error, i.e. 'invalid_credentials'

      # Pass through the original strategy callback error for easier debugging and error handling
      query_hash = env['rack.request.query_hash']
      strategy_error = nil
      if query_hash and query_hash['error']
        error_hash = {
          'error' => query_hash['error'],
          'error_reason' => query_hash['error_reason'],
          'error_description' => query_hash['error_description']
        }
        strategy_error = "&#{error_hash.to_param}"
      end
      new_path = "/api/checkpoint/v1/auth/failure?message=#{message_key}#{strategy_error}"
      [302, {'Location' => new_path, 'Content-Type'=> 'text/html'}, []]
    end
  end

  use Pebbles::Cors do |domain_name, origin|
    domain = Domain.resolve_from_host_name(domain_name)
    domain.allow_origin?(origin)
  end

  run CheckpointV1
end
