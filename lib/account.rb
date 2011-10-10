class Account < ActiveRecord::Base

  PROVIDERS = [:origo, :facebook, :twitter, :google]

  belongs_to :identity
  belongs_to :realm

  validates_presence_of :uid, :provider, :identity_id, :realm_id
  validates_inclusion_of :provider, :in => PROVIDERS + PROVIDERS.map(&:to_s)

  class << self
    def credentials_for(identity, provider)
      self.where(:identity_id => identity.id, :provider => provider).where('token IS NOT NULL and secret IS NOT NULL').first
    end

    def create_or_update(attributes)
      # these three come from twitter, and we don't have attributes for them
      keys = attributes.delete('credentials')
      profile_data_or_something = attributes.delete('extra')
      more_profile_data = attributes.delete('user_info')

      account = self.find_by_realm_id_and_provider_and_uid(attributes['realm_id'], attributes['provider'], attributes['uid'])
      account ||= Account.new(attributes)
      account.token = keys['token']
      account.secret = keys['secret']
      account.ensure_identity

      account.save!
      account
    end
  end

  def ensure_identity
    return identity if identity
    self.identity = Identity.create!(:kind => Species::Stub)
  end

  def authorize(credentials)
    self.token = credentials['token']
    self.secret = credentials['secret']
    self.save
  end

  def credentials
    {:token => token, :secret => secret}
  end

end
