require_relative 'species'

class Identity < ActiveRecord::Base
  include Species

  class NotAuthorized < Exception; end

  after_initialize :ensure_kind
  # after_save :ensure_person!
  # after_destroy :delete_person!

  has_many :accounts
  belongs_to :realm

  validates_inclusion_of :kind, :in => Species::KINDS, :allow_nil => true

  # realm.identities.from_provider('twitter')
  # identities are unique to a realm
  scope :from_provider, lambda { |provider|
    where("#{provider}_uid IS NOT NULL AND kind >= ?", Species::User)
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

  private

    def ensure_kind
      if self.kind.nil?
        self.kind = Species::Stub
      end
    end

end
