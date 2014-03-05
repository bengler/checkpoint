$app_name = 'checkpoint'

# Determine environment
ENV['RACK_ENV'] ||= "development"
$environment = ENV['RACK_ENV']

# Load application configuration for environment
$app_config = YAML::load(File.open("config/config.yml"))[$environment]

# Load site specific setup
require File.expand_path('config/site.rb') if File.exists?('config/site.rb')

require 'bundler'
Bundler.require

require 'pebblebed/sinatra'
require 'active_support/all'
require 'yaml'

Dir.glob('./lib/checkpoint/**/*.rb').each{ |lib| require lib }

ActiveRecord::Base.add_observer RiverNotifications.instance

db_config = YAML::load(File.open("config/database.yml"))[$environment]
ActiveRecord::Base.establish_connection(db_config)
$memcached = Dalli::Client.new unless ENV['RACK_ENV'] == 'test'

require File.expand_path('config/strategies.rb') if File.exists?('config/strategies.rb')

Pebblebed.config do
  service :vanilla
  service :checkpoint, :path => '/api/checkpoint'
  session_cookie 'aid.session'
end
