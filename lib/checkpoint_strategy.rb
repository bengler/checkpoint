module Hanuman
  class CheckpointStrategy

    def initialize(options = {})
      @options = options
    end

    def authenticate(username, password)
      user = Hanuman.user_service.authentication_by_email_or_phone(
        email_or_phone: username, password: password)
      return {uid: user.id.to_s, name: user.name, email: user.email}
    end

  end
end
