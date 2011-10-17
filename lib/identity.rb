class Identity < ActiveRecord::Base

  class NotAuthorized < Exception; end

  has_many :accounts, :dependent => :destroy
  belongs_to :realm

  validates_presence_of :realm_id

  def client_for(service)
    @clients ||= {}
    return @clients[service] if @clients[service]
    account = Account.find_by_identity_id_and_provider(self, service)    
    fail NotAuthorized.new("Identity #{id} is not authenticated for #{service.capitalize}") unless account.authorized?
    client_class = Object.const_get("#{service}_client".classify) # retrieve the client class, e.g. FacebookClient
    @clients[service] = client_class.new(self, account.credentials)
    @clients[service]
  end

  def orphanize!(new_identity)
    OrphanedIdentity.create!(:old_id => self.id, :identity => new_identity)
    self.destroy
  end

end
