source 'http://rubygems.org'

gem 'sinatra'
gem 'sinatra-activerecord'
gem 'activerecord', :require => 'active_record'
gem 'pg'
gem 'omniauth', '~> 0.3.0'
gem 'yajl-ruby', :require => "yajl"
gem "redis", "~> 2.2.2", :require => ["redis/connection/hiredis", "redis"]
gem "hiredis", "~> 0.3.1"
gem 'rabl'

group :development, :test do
  gem 'rspec', '~> 2.7.0.rc1'
  # a monkeypatch in rack 1.3.4 causes :WFKV_ to be declared twice
  # so to silence the warning, adding this line until we upgrade to
  # rack v. 1.3.5
  require 'uri/common'; ::URI.send :remove_const, :WFKV_
  gem 'rack-test'
  gem 'simplecov'
  gem 'capistrano', '=2.5.19'
  gem 'capistrano-ext', '=1.2.1'
  gem 'timecop'
  gem 'vcr'
  gem 'webmock'
  gem 'mock_redis'
end
