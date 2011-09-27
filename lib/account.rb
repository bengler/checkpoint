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
  end
end
