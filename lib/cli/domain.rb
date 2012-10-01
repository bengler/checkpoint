module Checkpoint
  module CLI
    class Domain < Thor

      desc "add DOMAIN", "Add a domain to realm"
      method_option :realm, :type => :string, :aliases => "-r", :required => true, :desc => "the realm to which this domain should be added"
      def add(domain)

        realm = ::Realm.find_by_label(options["realm"])

        unless realm
          puts "No such realm: #{options["realm"]}. Create it with \"checkpoint create #{options["realm"]}\""
          return
        end

        begin
          ::Domain.create!(:name => domain, :realm => realm)
        rescue Exception => e
          puts "Can't do that. #{e.message}"
        else
          puts "Added domain '#{domain}' to realm #{realm.label}"
        end

      end

    end
  end
end