class Account < ActiveRecord::Base

  PROVIDERS = [:origo, :facebook, :twitter, :google]

  belongs_to :identity
  belongs_to :realm

  validates_presence_of :uid, :provider, :identity_id, :realm_id
  validates_inclusion_of :provider, :in => PROVIDERS

  class << self
    def credentials_for(identity, provider)
      self.where(:identity_id => identity.id, :provider => provider).where('token IS NOT NULL and secret IS NOT NULL').first
    end

    def create_or_update(attributes)
      account = self.find_by_realm_id_provider_and_uid(attributes['realm_id'],
        attributes['provider'], attributes['uid'])
      account ||= Account.new(attributes)
      account.token = keys['token']
      account.secret = keys['secret']
      account.save!
    end
  end

  def ensure_identity!
    return identity if identity 
    self.identity = Identity.create!(:kind => Species::Stub)
    self.save!
    identity
  end


end
