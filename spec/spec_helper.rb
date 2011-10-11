require 'simplecov'
SimpleCov.add_filter 'spec'
SimpleCov.add_filter 'config'
SimpleCov.add_filter 'legacy'
SimpleCov.start

$:.unshift(File.dirname(File.dirname(__FILE__)))

ENV["RACK_ENV"] = "test"
require 'config/environment'

require 'api/v1'
require 'rack/test'
require 'config/logging'

set :environment, :test

# Run all examples in a transaction
RSpec.configure do |c|
  c.mock_with :rspec
  c.around(:each) do |example|
    ActiveRecord::Base.connection.transaction do
      example.run 
      raise ActiveRecord::Rollback
    end
  end
end

unless defined? Rails
  module Rails
    def self.env
      ENV["RACK_ENV"]
    end

    def self.root
      File.dirname(File.dirname(__FILE__))
    end
  end
end
