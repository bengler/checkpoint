require File.expand_path('config/site.rb') if File.exists?('config/site.rb')

require "bundler"
Bundler.require

require 'active_support/all'

require 'rails/observers/activerecord/base'
require 'rails/observers/activerecord/observer'

unless defined?(LOGGER)
  require 'logger'
  LOGGER = Logger.new($stdout)
  LOGGER.level = Logger::INFO
end

Dir.glob('./lib/checkpoint/**/*.rb').each{ |lib| require lib }

$config = YAML::load(File.open("config/database.yml"))
ENV['RACK_ENV'] ||= "development"
environment = ENV['RACK_ENV']

ActiveRecord::Base.add_observer RiverNotifications.instance

ActiveRecord::Base.establish_connection($config[environment])
$memcached = Dalli::Client.new unless ENV['RACK_ENV'] == 'test'

require File.expand_path('config/strategies.rb') if File.exists?('config/strategies.rb')

Pebblebed.config do
  service :vanilla
  service :checkpoint
end
