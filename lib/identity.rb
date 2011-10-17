class Identity < ActiveRecord::Base

  class NotAuthorized < Exception; end

  has_many :accounts
  belongs_to :realm

  # realm.identities.from_provider('twitter')
  # identities are unique to a realm
  scope :from_provider, lambda { |provider|
    where("#{provider}_uid IS NOT NULL")
  }

  def client_for(service)
    @clients ||= {}
    return @clients[service] if @clients[service]
    auth = Account.credentials_for(self, service)
    fail NotAuthorized.new("Identity #{id} is not authenticated for #{service.capitalize}") unless auth
    client_class = Object.const_get("#{service}_client".classify) # retrieve the client class, e.g. FacebookClient
    @clients[service] = client_class.new(self, auth)
    @clients[service]
  end

  def promote_to(species)
    self.kind = species if (kind < species)
  end


end
