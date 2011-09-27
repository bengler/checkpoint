environment = ENV['RAILS_ENV'] || "test"

require 'simplecov'
SimpleCov.add_filter 'vendor'
SimpleCov.add_filter 'spec'

require 'active_record'

$config = YAML::load(File.open("config/database.yml"))

ActiveRecord::Base.establish_connection($config[environment])

require './app/models/identity'
require './app/models/authentication'
require './app/models/territory'

require 'rspec'

# Run all examples in a transaction
RSpec.configure do |config|
  config.mock_with :rspec
  config.around(:each) do |example|
    ActiveRecord::Base.connection.transaction do
      example.run 
      raise ActiveRecord::Rollback
    end
  end
end
