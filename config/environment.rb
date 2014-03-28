$app_name = 'checkpoint'

# Determine environment
ENV['RACK_ENV'] ||= "development"
$environment = ENV['RACK_ENV']

# Load application configuration for environment
require 'yaml'
$app_config = YAML::load(File.open("config/config.yml"))[$environment]

# Load site specific setup
require File.expand_path('config/site.rb') if File.exists?('config/site.rb')

require 'bundler'
Bundler.require

# Default logger unless setup by site.rb
if !defined?(LOGGER)
  require 'logger'
  LOGGER = Logger.new(File.join($app_config['log_path'], 'common.log'))
end

Dir.glob('./lib/checkpoint/**/*.rb').each { |lib| require lib }

db_config = YAML::load(File.open("config/database.yml"))[$environment]
ActiveRecord::Base.establish_connection(db_config)
$memcached = Dalli::Client.new unless ENV['RACK_ENV'] == 'test'

require File.expand_path('config/strategies.rb') if File.exists?('config/strategies.rb')

Pebblebed.config do
  service :vanilla
  service :checkpoint, :path => '/api/checkpoint'
  session_cookie 'aid.session'
end
