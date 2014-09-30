require "seed"

module Checkpoint
  module CLI
    require "subcommands/domain"
    require "subcommands/identity"
    require "subcommands/realm"
    require "subcommands/session"

    class Checkpoint < Thor

      desc "domain SUBCOMMAND ...ARGS", "View/manage domains"
      subcommand "domain", Domain

      desc "identity SUBCOMMAND ...ARGS", "View/manage identities"
      subcommand "identity", Identity

      desc "realm SUBCOMMAND ...ARGS", "View/manage realms"
      subcommand "realm", Realm

      desc "realm SUBCOMMAND ...ARGS", "View/manage realms"
      subcommand "realm", Realm

      desc "session SUBCOMMAND ...ARGS", "View/manage sessions"
      subcommand "session", Session

      desc "seed", "Sets up some initial development realms"
      def seed
        Seed.create_realm('pebbles', :domain => 'pebbles.dev', :keys => {}, :god => true, :title => 'Pebbles Development Realm')
        Seed.create_realm('root', :domain => 'olympus.dev', :keys => {}, :god => true, :title => 'God of all realms')
        Seed.list
        puts "Remember to put oauth keys in the override.yml file"
      end


      desc "after_clone", "Makeover environment-specific data"
      def after_clone
        case ENV['RACK_ENV']
        when 'production'
          return
        when 'development'
          primary_domain = '.dev'
        when 'staging'
          primary_domain = '.staging.o5.no'
        end

        # rewrite callback urls
        Callback.all.each do |cb|
          cb.url = cb.url.sub('.o5.no', primary_domain)
          cb.save!
        end

        # add domains
        ::Realm.all.each do |realm|
          next if realm.label.include? '_'
          domain_name = "#{realm.label}#{primary_domain}"
          create_domain!(domain_name, realm)
          if ENV['RACK_ENV'] == 'staging'
            # we need dev domains on staging
            create_domain!(domain_name.sub('.staging.o5.no', '.dev'), realm)
          end
        end
      end


      def create_domain!(domain_name, realm)
        begin
          ::Domain.create!(:name => domain_name, :realm => realm)
          puts "Added domain '#{domain_name}' to realm #{realm.label}"
        rescue Exception => e
          puts "Can't create #{domain_name} on #{realm.label}. #{e.message}"
        end
      end

    end
  end
end
