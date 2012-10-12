module Checkpoint
  module CLI
    class Realm < Thor

      desc "create NAME", "create a development realm"
      method_option :title, :type => :string, :aliases => "-t", :desc => "the title of the realm"
      method_option :domain, :type => :string, :aliases => "-d", :desc => "the domain name (default will be <realm>.dev)"
      def create(label)
        require_memcached

        realm = ::Realm.find_by_label(label)
        if realm
          puts
          puts "That realm exists:"
          puts
        else
          begin
            realm = ::Seed.create_realm(label, :god => true, :title => options[:title], :domain => options[:domain])
          rescue Exception => e
            puts "Can't do that. #{e.message}"
          end
        end
        ::Seed.explain(realm)
      end

      desc "list", "list all realms and their domains. Shows all god sessions for the realm (one per line)."
      method_option :realm, :type => :string, :aliases => "-r", :desc => "Only list info for this realm."
      def list
        if options[:realm]
          realm = ::Realm.find_by_label(options[:realm])
          ::Seed.explain(realm)
        else
          if ::Realm.count == 0
            puts "No realms yet."
            return
          end
          ::Seed.list
        end
      end
      private
      def require_memcached
        unless system('ps aux | grep [m]emcached > /dev/null 2>&1')
          puts 'Memcached needs to be running. Bailing.'
          exit 1
        end
      end
    end
  end
end
