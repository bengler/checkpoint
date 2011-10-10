require 'simplecov'
SimpleCov.add_filter 'vendor'
SimpleCov.add_filter 'spec'

ENV['RAILS_ENV'] ||= "test"

RSpec.configure do |config|
  config.mock_with :rspec
end

unless defined? Rails
  module Rails
    def self.env
      'test'
    end

    def self.root
      File.dirname(File.dirname(__FILE__))
    end
  end
end
