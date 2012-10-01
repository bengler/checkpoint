module Checkpoint

  class CLI < Thor

    desc "seed", "sets up some initial realms to develop on"
    def seed
      Seed.create_realm('pebbles', :domain => 'pebbles.dev', :keys => {}, :god => true, :title => 'Pebbles Development Realm')
      Seed.create_realm('root', :domain => 'olympus.dev', :keys => {}, :god => true, :title => 'God of all realms')

      Seed.list

      puts "Remember to put oauth keys in the override.yml file"
    end

    desc "create REALM", "create a development realm"
    method_option :title, :type => :string, :aliases => "-t", :desc => "the title of the realm"
    method_option :domain, :type => :string, :aliases => "-d", :desc => "the domain name (default will be <realm>.dev)"
    def create(label)
      require_memcached

      realm = Realm.find_by_label(label)
      if realm
        puts
        puts "That realm exists:"
        puts
      else
        begin
          realm = Seed.create_realm(label, :god => true, :title => options[:title], :domain => options[:domain])
        rescue Exception => e
          puts "Can't do that. #{e.message}"
        end
      end
      Seed.explain(realm)

    end

    desc "add_domain DOMAIN", "add a domain to realm"
    method_option :realm, :type => :string, :aliases => "-r", :required => true, :desc => "the realm to which this domain should be added"
    def add_domain(domain)

      realm = Realm.find_by_label(options["realm"])

      begin
        Domain.create!(:name => domain, :realm => realm)
      rescue Exception => e
        puts "Can't do that. #{e.message}"
      else
        puts "Added domain '#{domain}' to realm #{realm.label}"
      end

    end

    desc "list", "list all realms and their domains. Shows all god sessions for the realm (one per line)."
    method_option :realm, :type => :string, :aliases => "-r", :desc => "Only list info for this realm."
    def list
      if options[:realm]
        realm = Realm.find_by_label(options[:realm])
        Seed.explain(realm)
      else
        if Realm.count == 0
          puts "No realms yet."
          return
        end
        Seed.list
      end
    end

    desc "become_god", "Provide god permissions to identity."
    method_option :identity_id, :type => :numeric, :aliases => "-i", :desc => "The identity id to make into a god."
    method_option :session, :type => :string, :required => true, :aliases => "-s", :desc => "The session key whose identity should be made into a god."
    def become_god
      identity = nil
      if options[:session]
        identity = Session.find_by_key(options[:session]).identity
      else
        identity = Identity.find options[:identity_id]
      end

      if identity
        identity.update_attribute(:god, true)
        puts "Identity #{identity.id} has been granted god permissions."
      else
        puts "Could not find identity."
      end
    end

    desc "create_session", "Create new session to realm"
    method_option :realm, :type => :string, :aliases => "-r", :required => true
    method_option :session, :type => :string, :aliases => "-s", :required => true
    method_option :god, :type => :boolean, :aliases => "-g"
    def create_session
      Session.transaction do
        realm = Realm.where(:label => options[:realm]).first
        unless realm
          puts "Sorry, no realm labeled \'#{options[:realm]}\'."
          puts "Create it like so: \'bx ./bin/checkpoint create #{options[:realm]}\'."
          return
        end
        identity = Identity.create(:realm_id => realm.id, :god => !!options[:god])
        Session.create(:identity_id => identity.id, :key => options[:session])
      end
      puts "Successfuly created new session"
    rescue Exception => e
      puts e.message
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

