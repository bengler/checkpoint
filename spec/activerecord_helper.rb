require 'spec_helper'
require 'active_record'

$config = YAML::load(File.open("config/database.yml"))

ActiveRecord::Base.establish_connection($config[ENV['RAILS_ENV']])

require './app/models/identity'
require './app/models/account'
require './app/models/realm'

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
