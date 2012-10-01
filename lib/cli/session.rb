module Checkpoint
  module CLI
    class Session < Thor
      desc "create", "Create new session to realm"
      method_option :realm, :type => :string, :aliases => "-r", :required => true
      method_option :session, :type => :string, :aliases => "-s", :required => true
      method_option :god, :type => :boolean, :aliases => "-g"
      def create
        ::Session.transaction do
          realm = ::Realm.where(:label => options[:realm]).first
          unless realm
            puts "Sorry, no realm labeled \'#{options[:realm]}\'."
            puts "Create it like so: \'bx ./bin/checkpoint create #{options[:realm]}\'."
            return
          end
          identity = ::Identity.create(:realm_id => realm.id, :god => !!options[:god])
          ::Session.create(:identity_id => identity.id, :key => options[:session])
        end
        puts "Successfuly created new session"
      rescue Exception => e
        puts e.message
      end
    end
  end
end