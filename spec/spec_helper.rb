require 'simplecov'
require 'memcache_mock'

SimpleCov.add_filter 'spec'
SimpleCov.add_filter 'config'
SimpleCov.start

$:.unshift(File.dirname(File.dirname(__FILE__)))

ENV["RACK_ENV"] = "test"

require 'config/environment'
require 'api/v1'

require 'rack/test'
require 'webmock/rspec'
require 'vcr'
require 'timecop'

keys = Realm.environment_overrides['valid_realm']

VCR.configure do |c|
  c.cassette_library_dir = 'spec/fixtures/vcr_cassettes'
  c.hook_into :webmock
  c.filter_sensitive_data("REDACTED:TWITTER_PASSWORD") { ENV['CHECKPOINT_TWITTER_PASSWORD'] }
  c.filter_sensitive_data("REDACTED:TWITTER_OAUTH_KEY") { if keys then keys['services']['twitter']['consumer_key'] end }
  c.filter_sensitive_data("REDACTED:TWITTER_OAUTH_SECRET") { if keys then keys['services']['twitter']['consumer_secret'] end }
end

ActiveRecord::Base.logger = Logger.new('/dev/null')
ActiveRecord::Base.logger.level = Logger::INFO

LOGGER.level = Logger::WARN

set :environment, :test

# Run all examples in a transaction
RSpec.configure do |c|
  c.mock_with :rspec
  c.before :each do
    WebMock.reset!
  end
  c.around(:each) do |example|
    clear_cookies if respond_to?(:clear_cookies)
    $memcached = MemcacheMock.new
    ActiveRecord::Base.connection.transaction do
      example.run
      raise ActiveRecord::Rollback
    end
    t = Time.now
    Timecop.freeze(t)
  end

  c.after(:each) do
    Timecop.return
  end
end
