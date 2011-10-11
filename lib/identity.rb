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

  class << self
    def establish(auth_data)
      account = Account.find_by_realm_id_and_provider_and_uid(auth_data['realm_id'], auth_data['provider'], auth_data['uid'])

      unless account
        # we're probably going to want to have an adapter for auth_data so that we don't have to know about providers here
        identity = Identity.create!(:realm_id => auth_data['realm_id'], :byline_name => auth_data['user_info']['name'])
        account = identity.ensure_account(auth_data)
      end

      account.authorize(auth_data['credentials'])
      account.identity.promote_to(Species::User)
      account.identity.save!

      account.identity
    end
  end

  def promote_to(species)
    self.kind = species if (kind < species)
  end

  def ensure_account(auth_data)
    account = Account.new(:identity_id => id, :provider => auth_data['provider'], :uid => auth_data['uid'], :realm_id => auth_data['realm_id'])
    self.accounts << account
    self.save!
    account
  end

  def update_from_accounts!
    self.accounts.each do |account|
      self.kind = Species::User if account.secret
      self.b
    end
  end

  # Who recruited this user from contacts somewhere?
  # def enrolled_by_user
  #   if self.enrolled_by_user_id
  #     return Identity.find(self.enrolled_by_user_id)
  #   end
  # end

  #def person
  #  Person.find(:user_id => self.id).first
  #end

  # def followers
  #   list = self.person.followers.collect{|p| p.user_id if p.respond_to?(:user_id)}.compact
  #   return Identity.where(:id => list) if list.any?
  #   []
  # end

  # def following
  #   list = self.person.following.collect{|p| p.user_id if p.respond_to?(:user_id)}.compact
  #   return Identity.where(:id => list) if list.any?
  #   []
  # end

  # # Those I follow who follow me
  # def reciprocating_followers
  #   list = self.person.reciprocating_followers.compact
  #   return Identity.where(:id => list) if list.any?
  #   []
  # end

  # Returns friends for this user from a provider (string,sym)
  # def provider_friends(provider)
  #   list = self.person.following.collect{|p| p.user_id if p.respond_to?(:user_id)}.compact
  #   return Identity.all_users_from_provider(provider).where(:id => list) if list.any?
  #   []
  # end

  # # Returns a array of user ids that are relevant for this user
  # def user_ids_of_interest(provider=nil)
  #   self.person.following.collect{|p| p.user_id if p.respond_to?(:user_id)}.compact.push(self.id)
  # end

  # Method for creating or updating a user from authentication data
  # @auth_data => Omniauth auth data hash (OBS: stringified keys)
  # @user => Identity to update (optional), default is to create new user
  # def self.create_or_update(auth_data, identity=nil)
  #   # Do in a transaction!
  #   Identity.transaction do
  #     auth = Account.where(:realm_id => auth_data['realm_id'], :provider => auth_data['provider'].to_sym, :uid => auth_data['uid']).first
  #     unless identity
  #       identity = auth.identity if auth
  #       identity ||= Identity.new(
  #         :enrolled_by_provider => auth_data['provider'],
  #         :realm_id => auth_data['realm_id'],
  #         :enrolled_by_identity_id => auth_data['enrolled_by_identity_id'],
  #         :byline_name => auth_data['user_info']['name']
  #       )
  #     end
  #     identity.kind = auth_data['kind'] if auth_data['kind']
  #     identity.byline_name ||= auth_data['user_info']['name']
  #     identity.email ||= auth_data['user_info']['email']
  #     identity.mobile ||= auth_data['user_info']['mobile']
  #     identity.save
  #     auth ||= Account.create!(:realm_id => auth_data['realm_id'], :provider => auth_data['provider'].to_sym, :uid => auth_data['uid'], :identity => identity)
  #     # user.person.set_user_data(auth_data['user_info'])
  #     # user.person.save
  #     identity
  #   end
  # end

  private

    # Callback for after save
    # def ensure_person!
    #   if self.person.nil?
    #     Person.create(
    #       :name => self.name,
    #       :user => self
    #     )
    #   end
    # end

    # Callback for before save
    def ensure_kind
      if self.kind.nil?
        self.kind = Species::Stub
      end
    end

    # Callback for after destroy
    # def delete_person!
    #   self.person.delete
    # end

end
