class Account < ActiveRecord::Base

  PROVIDERS = [:origo, :facebook, :twitter, :google]

  belongs_to :identity
  belongs_to :realm

  validates_presence_of :uid, :provider, :identity, :realm_id
  validates_inclusion_of :provider, :in => PROVIDERS + PROVIDERS.map(&:to_s)

  before_validation :ensure_identity

  attr_accessor :auth_data

  class << self
    def credentials_for(identity, provider)
      self.where(:identity_id => identity.id, :provider => provider).where('token IS NOT NULL and secret IS NOT NULL').first
    end

    def find_or_create_with_auth_data(auth_data)
      attributes = {
        :provider => auth_data['provider'],
        :uid => auth_data['uid'],
        :realm_id => auth_data['realm_id'],
        # do these get updated if record is found?
        :token => auth_data['credentials']['token'],
        :secret => auth_data['credentials']['secret'],
        :auth_data => auth_data
      }
      find_or_create_by_provider_and_realm_id_and_uid(attributes)
    end
  end

  def promote_to(species)
    identity.promote_to(species)
  end

  def credentials
    {:token => token, :secret => secret}
  end

  def ensure_identity
    build_identity(:realm_id => realm_id) unless identity
  end

end
