require 'spec_helper'
require 'active_record'

$config = YAML::load(File.open("config/database.yml"))

ActiveRecord::Base.establish_connection($config[ENV['RAILS_ENV']])

require './lib/identity'
require './lib/account'
require './lib/realm'

# Run all examples in a transaction
RSpec.configure do |config|
  config.around(:each) do |example|
    ActiveRecord::Base.connection.transaction do
      example.run 
      raise ActiveRecord::Rollback
    end
  end
end
