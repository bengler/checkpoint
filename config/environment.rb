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

ENV['RACK_ENV'] ||= "development"
environment = ENV['RACK_ENV']

ActiveRecord::Base.add_observer RiverNotifications.instance unless environment == 'test'
ActiveRecord::Base.logger = LOGGER
ActiveRecord::Base.configurations = YAML.load(
  ERB.new(File.read(File.expand_path("../database.yml", __FILE__))).result)
ActiveRecord::Base.include_root_in_json = true
ActiveRecord::Base.establish_connection(ActiveRecord::Base.configurations[environment])

OmniAuth.config.logger = LOGGER

$memcached = Dalli::Client.new unless ENV['RACK_ENV'] == 'test'

require File.expand_path('config/strategies.rb') if File.exists?('config/strategies.rb')

Pebblebed.config do
  service :vanilla
  service :checkpoint
end
