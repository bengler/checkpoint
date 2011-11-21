source 'http://rubygems.org'

gem 'sinatra'
gem 'sinatra-activerecord'
gem 'activerecord', :require => 'active_record'
gem 'activesupport'
gem 'pg'
gem 'omniauth', '~> 1.0.0.rc2'
gem 'omniauth-facebook', '~> 1.0.0.rc1', :git => 'https://github.com/mkdynamic/omniauth-facebook.git'
gem 'omniauth-contrib', '~> 1.0.0.rc2', :git => 'https://github.com/intridea/omniauth-contrib.git'
gem 'omniauth-oauth', '~> 1.0.0.rc2', :git => 'https://github.com/intridea/omniauth-oauth.git'
gem 'omniauth-origo', '~> 1.0.0.rc2', :git => 'https://github.com/origo/omniauth-origo.git'
gem 'yajl-ruby', :require => "yajl"
gem "redis", "~> 2.2.2", :require => ["redis/connection/hiredis", "redis"]
gem "hiredis", "~> 0.3.1"
gem 'rabl'

group :development, :test do
  gem 'rake'
  gem 'rspec', '~> 2.7.0.rc1'
  gem 'simplecov'
  gem 'rspec-extra-formatters'
  # a monkeypatch in rack 1.3.4 causes :WFKV_ to be declared twice
  # so to silence the warning, adding this line until we upgrade to
  # rack v. 1.3.5
  #require 'uri/common'; ::URI.send :remove_const, :WFKV_
  gem 'rack-test'
  gem 'capistrano', '=2.5.19'
  gem 'capistrano-ext', '=1.2.1'
  gem 'timecop'
  gem 'vcr'
  gem 'webmock'
  gem 'mock_redis'
end
