require "hanuman/checkpoint/strategy"
require "hanuman/config"
require "amedia/properties"

environment = ENV['RACK_ENV']

File.open("config/amedia-properties.yml", 'r') do |f|
  Amedia::Properties::Config.load f, environment
end

File.open("config/hanuman.yml", 'r') do |f|
  Hanuman::Config.load(f , environment)
end

Checkpoint.strategies << Hanuman::Strategy.new