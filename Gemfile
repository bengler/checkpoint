source 'https://rubygems.org'

gem 'sinatra'
gem 'sinatra-contrib', require: false
gem 'sinatra-activerecord', '~> 2.0'
gem 'rack-contrib'

# Remove this git reference after version > 1.5.2 is released
gem 'rack-protection', :git => 'git://github.com/rkh/rack-protection.git'

gem 'activerecord', '~> 4.2', :require => 'active_record'
gem 'activesupport', '~> 4.2'
gem 'rails-observers', '~> 0.1', require: false
gem 'pg', '~> 0.17'
gem 'omniauth', '~> 1.2.2'
gem 'omniauth-twitter'
gem 'omniauth-facebook'
gem 'omniauth-oauth'
gem 'omniauth-oauth2', '~> 1.3.1'
gem 'omniauth-origo'
gem 'omniauth-vanilla', :git => 'git://github.com/bengler/omniauth-vanilla.git', :branch => 'omniauth1.2'
gem 'omniauth-evernote'
gem 'omniauth-aid'
gem 'omniauth-google-oauth2'
gem 'pebblebed', ">=0.2.0"
gem 'pebbles-uid'
gem 'pebbles-cors', :git => 'git://github.com/bengler/pebbles-cors.git'
gem 'pebbles-path', '>=0.0.3'
gem 'yajl-ruby', :require => 'yajl'
gem 'dalli', '~> 2.1.0'
gem 'thor'
gem 'petroglyph'
gem 'rake'
gem 'queryparams'
gem 'simpleidn', '~> 0.0.4'
gem 'rest-client', :require => false  # Used by origo.thor
gem 'ar-tsvectors', '~> 1.0', :require => 'activerecord_tsvectors'
gem 'curb', '>= 0.8.8'

group :development, :test do
  gem 'simplecov'
  gem 'rspec', '~> 2.8'
  gem 'webmock', '~> 1.8.11'
  gem 'vcr'
  gem 'timecop', '~> 0.3.5'
  gem 'rack-test'
  gem "memcache_mock"
end

group :production do
  gem 'airbrake', '~> 3.1.4', :require => false
  gem 'unicorn'
end
