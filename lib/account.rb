class Account < ActiveRecord::Base

  belongs_to :identity
  belongs_to :realm

  validates_presence_of :uid, :provider, :realm_id

  class << self
    # Creates or updates an account from auth data as provided by 
    # omniauth. An existing identity or a realm must be provided 
    # in the options. E.g.: 
    #     Account.declare_with_omniauth(auth, :realm => current_realm) # creates a new user
    #     Account.declare_with_omniauth(auth, :identity => current_identity) # attaches an account to an existing identity
    # If the account was previously attached to an identity, it will be moved to this identity and the former identity
    # will be scrapped along with any account it may have had. So there.
    def declare_with_omniauth(auth_data, options = {})
      identity = options[:identity] 
      unless identity             
        raise ArgumentError, "Identity or realm must be specified" unless options[:realm]
        identity ||= Identity.create!(:realm => options[:realm])
      end

      attributes = {
        :provider => auth_data['provider'],
        :uid => auth_data['uid'],
        :realm_id => identity.realm.id,
      }

      account = find_by_provider_and_realm_id_and_uid(attributes[:provider], attributes[:realm_id], attributes[:uid])
      if account && account.identity != identity
        account.identity.orphanize!(identity)
        account = nil
      end

      account ||= new(attributes)
      account.attributes = {
        :identity =>     identity,
        :token =>        auth_data['credentials']['token'],
        :secret =>       auth_data['credentials']['secret'],
        :nickname =>     auth_data['user_info']['nickname'],
        :name =>         auth_data['user_info']['name'],
        :location =>     auth_data['user_info']['location'],
        :image_url =>    auth_data['user_info']['image'],
        :description =>  auth_data['user_info']['description'],
        :profile_url =>  auth_data['user_info']['urls']['Twitter']
      }
      account.save!
      account
    end
  end

  def authorized?
    !!credentials
  end

  def credentials
    return nil unless token && secret
    {:token => token, :secret => secret}
  end

end
