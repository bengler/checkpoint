class Account < ActiveRecord::Base

  class InUseError < Exception; end

  belongs_to :identity
  belongs_to :realm

  after_destroy :update_identity_primary_account
  after_save :update_session_manager

  validates_presence_of :uid, :provider, :realm_id

  class << self
    # Creates or updates an account from auth data as provided by
    # omniauth. An existing identity or a realm must be provided
    # see https://github.com/intridea/omniauth/wiki/Auth-Hash-Schema for an overview of the data omniauth provides
    # in the options. E.g.:
    #     Account.declare_with_omniauth(auth, :realm => current_realm) # creates a new user
    #     Account.declare_with_omniauth(auth, :identity => current_identity) # attaches an account to an existing identity
    # If the account was previously attached to an identity, an InUseError exception will be raised.
    def declare_with_omniauth(auth_data, options = {})
      identity = options[:identity]      
      raise ArgumentError, "Identity or realm must be specified" unless (options[:realm] || identity)

      attributes = {
        :provider => auth_data['provider'],
        :uid => auth_data['uid'],
        :realm_id => options[:realm].try(:id) || identity.realm.id,
      }

      account = find_by_provider_and_realm_id_and_uid(attributes[:provider], attributes[:realm_id], attributes[:uid])

      identity ||= account.try(:identity) || Identity.create!(:realm => options[:realm])

      if account && account.identity != identity
        raise Account::InUseError.new('This account is already bound to a different identity.')
      end

      account ||= new(attributes)
      account.attributes = {
        :identity =>     identity,
        :token =>        auth_data['credentials']['token'],
        :secret =>       auth_data['credentials']['secret'],
        :nickname =>     auth_data['info']['nickname'],
        :name =>         auth_data['info']['name'],
        :location =>     auth_data['info']['location'],
        :image_url =>    auth_data['info']['image'],
        :description =>  auth_data['info']['description'],
        :profile_url =>  auth_data['info']['urls']['Twitter']
      }
      account.save!

      identity.ensure_primary_account
      identity.save!

      account
    end
  end

  def authorized?
    !!credentials
  end

  def primary?
    identity.try(:primary_account_id) == self.id
  end

  def credentials
    return nil unless token && secret
    {:token => token, :secret => secret}
  end

  private

  def update_identity_primary_account
    return unless self.primary?
    self.identity.primary_account = nil
    self.identity.ensure_primary_account
    self.identity.save!
  end

  def update_session_manager
    SessionManager.update_identity_record(self.identity) if self.primary?
  end

end
