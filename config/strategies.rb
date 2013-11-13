require "hanuman/checkpoint/strategy"
require "hanuman/config"
require "amedia/properties"

environment = ENV['RACK_ENV']

if environment == 'test'
  # We don't want to test Gaia's inner workings directly here, so we mock it
  # This hack should be done in spec_helper, but test environment is also faked
  # in Rake-tasks for DB:migration.
  module Gaia
    class ConfigService
      def get_property property
        if property == "hanuman.director.url.prefix"
          OpenStruct.new({
                           name: property,
                           value: "http://example.org/this_should_be_stubbed"
                         })
        end
      end
    end
  end
else 
  File.open("config/amedia-properties.yml", 'r') do |f|
    Amedia::Properties::Config.load f, environment
  end
end

File.open("config/hanuman.yml", 'r') do |f|
  Hanuman::Config.load(f , environment)
end

Checkpoint.strategies << Hanuman::Strategy.new
