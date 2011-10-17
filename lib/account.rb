class Account < ActiveRecord::Base

  PROVIDERS = [:origo, :facebook, :twitter, :google]

  belongs_to :identity
  belongs_to :realm

  validates_presence_of :uid, :provider, :realm_id
  validates_inclusion_of :provider, :in => PROVIDERS + PROVIDERS.map(&:to_s)

  # after_save :ensure_identity ?? only if we have auth data

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
        # No, attributes which should potentially update should be in the method name
        # --> find_or_create_by_provider_and_realm_id_and_uid_and_token_and_secret_and_authdata(attributes)
        # Thomas (not changing the code 'cause I'm unsure if this is what we want :-)
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

  def find_or_create_identity
  end

end
