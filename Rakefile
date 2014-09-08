$:.unshift(File.dirname(__FILE__))

require "sinatra/activerecord/rake"
require_relative 'config/environment'

# TODO: This exists only so CI server will find the task. Change CI
#   script so we don't need it.
namespace :db do
  namespace :test do
    desc "Prepare test database."
    task :prepare
  end
end

namespace :maintenance do
  desc "delete anonymous identities that have not been seen for a month"
  task :delete_inactive_anonymous_identities do
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
