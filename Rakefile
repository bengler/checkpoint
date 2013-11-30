$:.unshift(File.dirname(__FILE__))

require 'sinatra/activerecord/rake'
require 'bengler_test_helper/tasks' if ['development', 'test'].include?(ENV['RACK_ENV'] || ENV['RAILS_ENV'] || 'development')

task :environment do
  require 'config/environment'
  ActiveRecord::Base.logger.level = Logger::INFO if ActiveRecord::Base.logger
end

task "db:schema:load" => :environment
task "db:schema:dump" => :environment

namespace :db do
  desc "bootstrap db user, recreate, run migrations"
  task :bootstrap do
    name = "checkpoint"
    `createuser -sdR #{name}`
    `createdb -O #{name} #{name}_development`
    Rake::Task['db:migrate'].invoke
    Rake::Task['db:test:prepare'].invoke
  end

  task :migrate => :environment

  desc "nuke db, recreate, run migrations"
  task :nuke do
    name = "checkpoint"
    `dropdb #{name}_development`
    `createdb -O #{name} #{name}_development`
    Rake::Task['db:migrate'].invoke
    Rake::Task['db:test:prepare'].invoke
  end
end

namespace :maintenance do
  desc "delete anonymous identities that have not been seen for a month"
  task :delete_inactive_anonymous_identities => :environment do
    Identity.anonymous.not_seen_for_more_than_days(30).find_in_batches(:batch_size => 300) do |identities|
      print '.'
      Identity.connection.transaction do
        identities.map(&:destroy)
      end
    end
    puts
    puts "Deleting void sessions"
    Identity.connection.execute("delete from sessions where identity_id is null and updated_at < now() - interval '24 hours'")
    puts "Deleting old session_ips"
    Identity.connection.execute("delete from identity_ips where created_at < now() - interval '30 days'")
  end
end
