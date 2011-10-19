$:.unshift(File.dirname(__FILE__))

require 'config/environment'
require 'sinatra/activerecord/rake'

namespace :db do

  desc "bootstrap db user, recreate, run migrations"
  task :bootstrap do
    `createuser -sdR checkpoint`
    `createdb -O checkpoint checkpoint_development`
    Rake::Task['db:migrate'].invoke
  end

  namespace :schema do
    desc "dump database schema"
    task :dump do
      ActiveRecord::SchemaDumper.dump(ActiveRecord::Base.connection, File.open('db/schema.rb', 'w', :encoding => 'UTF-8'))
    end
  end

  task :migrate do
    Rake::Task["db:schema:dump"].invoke
  end

  namespace :test do
    desc "create test database"
    task :prepare do

      ENV["RACK_ENV"] = "test"

      `dropdb -U postgres #{$config['test']['database']}`
      `createdb -U postgres -O #{$config['test']['username']} #{$config['test']['database']}`

      ActiveRecord::Base.establish_connection($config['test'])
      load('db/schema.rb')
    end
  end

  desc "nuke db, recreate, run migrations"
  task :nuke do
    `dropdb checkpoint_development`
    `createdb -O checkpoint checkpoint_development`
    Rake::Task['db:migrate'].invoke
  end

  desc "add seed data to database"
  task :seed do
    require_relative './db/seeds'
  end

end
