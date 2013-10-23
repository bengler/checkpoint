module Hanuman
  class CheckpointStrategy

    def initialize(options = {})
      @options = options
    end

    def authenticate(username, password)
      credentials = {
        :email_or_phone => username,
        :password       => password,
      }
      user = Hanuman.user_service.authentication_by_email_or_phone(credentials)

      account = {
        :uid   => user.id.to_s,
        :name  => user.name,
        :email => user.email
      }
      account
    end

  end
end
