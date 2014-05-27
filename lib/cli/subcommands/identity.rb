module Checkpoint
  module CLI
    class Identity < Thor

      desc 'generate_app_key APPNAME', 'Create a god identity for an application. This ' \
        'will be create a god identity and a session, and prefix the session ' \
        'key with the app name.'
      method_option :realm,
        type: :string,
        required: true,
        aliases: '-r',
        desc: 'The name of the realm'
      def generate_app_key(app)
        ActiveRecord::Base.transaction do
          realm = ::Realm.where(label: options[:realm]).first
          unless realm
            abort "No realm named \'#{options[:realm]}\'."
          end

          identity = ::Identity.create(realm: realm, god: true)

          session = ::Session.create(
            identity: identity,
            key: [app, ::Session.random_key].join('-'))

          puts "Created new session with key:"
          puts "  \e[31;1m#{session.key}\e[0m"
        end
      end

      desc "become_god", "Provide god permissions to identity."
      method_option :identity_id, :type => :numeric, :aliases => "-i", :desc => "The identity id to make into a god."
      method_option :session, :type => :string, :required => true, :aliases => "-s", :desc => "The session key whose identity should be made into a god."
      def become_god
        identity = nil
        if options[:session]
          identity = ::Session.find_by_key(options[:session]).identity
        else
          identity = ::Identity.find options[:identity_id]
        end

        if identity
          identity.update_attribute(:god, true)
          puts "Identity #{identity.id} has been granted god permissions."
        else
          puts "Could not find identity."
        end
      end
    end
  end
end
