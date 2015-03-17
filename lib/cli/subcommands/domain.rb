module Checkpoint
  module CLI
    class Domain < Thor

      desc "add DOMAIN", "Add a domain to realm"
      method_option :realm,
        type: :string,
        aliases: "-r",
        required: true,
        desc: "the realm to which this domain should be added"
      method_option :primary,
        type: :boolean,
        aliases: "-p",
        desc: "Set as primary"
      def add(domain_name)
        ActiveRecord::Base.transaction do
          realm = ::Realm.find_by_label(options["realm"])
          unless realm
            puts "No such realm: #{options["realm"]}. Create it with \"checkpoint realm create #{options["realm"]}\""
            return
          end

          domain = begin
            ::Domain.create!(name: domain_name, realm: realm)
          rescue Exception => e
            abort e.message
          end

          if options[:primary]
            realm.primary_domain = domain
            realm.save!
          end

          puts "Added domain_name '#{domain.name}' to realm #{realm.label}"
        end
      end

      desc "list", "List domains"
      method_option :realm, :type => :string, :aliases => "-r", :desc => "List domains for this realm"
      def list

        realms = options['realm'] ? [::Realm.find_by_label(options["realm"])] : ::Realm.all

        if realms.empty?
          puts "No realms #{"matching #{options["realm"]}" if options["realm"]}."
          return
        end

        puts realms.map { |realm|
          out = ""
          out << "* #{realm.label}\n"
          realm.domains.each do |domain|
            out << "  #{domain.name}\n"
          end
          out << "\n"
        }
      end
    end
  end
end
