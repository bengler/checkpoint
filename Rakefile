$:.unshift(File.dirname(__FILE__))

require 'sinatra/activerecord/rake'
begin
  require 'bengler_test_helper/tasks'
rescue LoadError
  puts "Unable to load bengler_test_helper. This is probably ok in production."
end

task :environment do
  require 'config/environment'
end

namespace :db do

  desc "bootstrap db user, recreate, run migrations"
  task :bootstrap do
    name = "checkpoint"
    `createuser -sdR #{name}`
    `createdb -O #{name} #{name}_development`
    Rake::Task['db:migrate'].invoke
    Rake::Task['db:test:prepare'].invoke
  end

  task :migrate => :environment do
    Rake::Task["db:structure:dump"].invoke
  end

  desc "nuke db, recreate, run migrations"
  task :nuke do
    name = "checkpoint"
    `dropdb #{name}_development`
    `createdb -O #{name} #{name}_development`
    Rake::Task['db:migrate'].invoke
    Rake::Task['db:test:prepare'].invoke
  end

  desc "add seed data to database"
  task :seed => :environment do
    require_relative './db/seeds'
  end
end
