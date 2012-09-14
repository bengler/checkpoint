$:.unshift(File.dirname(__FILE__))

require 'config/environment'
require 'api/v1'
require 'rack/contrib'

ENV['RACK_ENV'] ||= 'development'
set :environment, ENV['RACK_ENV'].to_sym

map "/api/checkpoint/v1" do
  use Rack::PostBodyContentTypeParser
  use Rack::MethodOverride
  use Rack::Session::Cookie, :key => 'checkpoint.cookie',
    :secret => 'ice cream sandwich'

  use OmniAuth::Builder do
    provider :twitter, nil, nil, :setup => true
    provider :facebook, nil, :setup => true
    provider :origo, nil, nil, :setup => true
    provider :vanilla, nil, nil, :setup => true
    #provider :openid, nil, :name => 'google', :identifier => 'https://www.google.com/accounts/o8/id'
    provider :google_oauth2, nil, nil, :setup => true

    on_failure do |env|
      message_key = env['omniauth.error.type']
      new_path = "/api/checkpoint/v1/auth/failure?message=#{message_key}"
      [302, {'Location' => new_path, 'Content-Type'=> 'text/html'}, []]
    end
  end

  use Pebbles::Cors do |domain|
    domain = Domain.find_by_name(domain)
    domain ? domain.realm.domains.map(&:name) : []
  end

  run CheckpointV1
end
