source 'https://rubygems.org'

gem 'sinatra', '~> 1.4.6'
gem 'sinatra-contrib', '~> 1.4.6', require: false
gem 'sinatra-activerecord', '~> 2.0'
gem 'rack-contrib', '~> 1.4.0'

# Remove this git reference after version > 1.5.2 is released
gem 'rack-protection', :git => 'https://github.com/rkh/rack-protection.git'
gem 'addressable', '~> 2.3.8'
gem 'activerecord', '~> 4.2.7.1', :require => 'active_record'
gem 'activesupport', '~> 4.2.5'
gem 'rails-observers', '~> 0.1', require: false
gem 'pg', '~> 0.17'
gem 'omniauth', '~> 1.7.1'
gem 'omniauth-twitter', '~> 1.2.1'
gem 'omniauth-facebook', '~> 4.0.0'
gem 'omniauth-oauth', '~> 1.1.0'
gem 'omniauth-oauth2', '~> 1.3.1'
gem 'omniauth-origo', '~> 1.2.0'
gem 'omniauth-vanilla', :git => 'https://github.com/bengler/omniauth-vanilla.git', :branch => 'omniauth1.2'
gem 'omniauth-evernote', '~> 1.2.1'
gem 'omniauth-aid', :git => 'https://github.com/bengler/omniauth-aid.git'
gem 'omniauth-google-oauth2', '~> 0.2.8'
gem 'pebblebed', "~> 0.3.26"
gem 'pebbles-uid', '~> 0.0.22'
gem 'pebbles-cors', :git => 'https://github.com/bengler/pebbles-cors.git'
gem 'pebbles-path', '>=0.0.3'
gem 'yajl-ruby', '1.3.1', :require => 'yajl'
gem 'dalli', '~> 2.1.0'
gem 'thor', '~> 0.19.1'
gem 'petroglyph', '~> 0.0.7'
gem 'rake', '~> 10.4.2'
gem 'queryparams', '~> 0.0.3'
gem 'simpleidn', '~> 0.0.4'
gem 'rest-client', '~> 1.8.0', :require => false  # Used by origo.thor
gem 'ar-tsvectors', '~> 1.0', :require => 'activerecord_tsvectors'
gem 'curb', '>= 0.8.8'

group :development, :test do
  gem 'simplecov', '~> 0.10.0'
  gem 'rspec', '~> 2.8'
  gem 'webmock', '~> 1.8.11'
  gem 'vcr', '~> 2.9.3'
  gem 'timecop', '~> 0.3.5'
  gem 'rack-test', '~> 0.6.3'
  gem "memcache_mock", '~> 0.0.14'
end

group :production do
  gem 'airbrake', '~> 3.1.4', :require => false
  gem 'unicorn', '~> 4.9.0'
end
