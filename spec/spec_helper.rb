ENV['RAILS_ENV'] ||= "test"

require 'simplecov'
SimpleCov.add_filter 'vendor'
SimpleCov.add_filter 'spec'

require 'rspec'

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
