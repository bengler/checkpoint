module Checkpoint
  module CLI
    class Identity < Thor

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
