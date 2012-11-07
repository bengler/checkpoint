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

    end
  end
end

