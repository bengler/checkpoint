class Account < ActiveRecord::Base

  class InUseError < StandardError
    attr_reader :identity_id
    def initialize(message, options = {})
      @identity_id = options[:identity_id]
      super(message)
    end
  end

  belongs_to :identity
  belongs_to :realm

  after_create :update_identity_primary_account
  before_destroy :reset_identity_primary_account
  after_destroy :update_identity_primary_account

  after_save :invalidate_cache
  after_save lambda {
    self.identity.update_fingerprints_from_account!(self) if self.identity
  }
  before_destroy :invalidate_cache
  before_validation :infer_realm

  validates_presence_of :uid, :provider, :realm_id
  validates_uniqueness_of :uid, :scope => [:realm_id, :provider]

  class << self

    # Creates or updates account information as provided by record attributes. Will create an account
    # if missing, or update in place when an account with the same identity and uid exists. If an account
    # with the same provider and uid exists, but for another identity, an InUseError is raised.
    def declare!(attributes)
      attributes.symbolize_keys!
      begin
        # Optimistically we just go for it. Validations and an uniqueness-index will reject us if we are
        # in error.
        return Account.create!(attributes)
      rescue ActiveRecord::RecordInvalid, ActiveRecord::RecordNotUnique => e
        # Handles uniqueness violations when raised either as validation failure, or
        # in the case of a data-race: violation of uniqueness constraint in postgres.
        case e
        when ActiveRecord::RecordInvalid
          # Reraise if other validation error
          raise unless e.record.is_a?(Account) && e.record.errors.messages[:uid] &&
            e.record.errors.messages[:uid].join(' ') =~ /been taken/
        when ActiveRecord::RecordNotUnique
          # Reraise unless uniqueness violation
          raise unless e.message =~ /violates.*account_uniqueness_index/
        end

        target_identity = attributes[:identity] || Identity.find(attributes[:identity_id])
        account = Account.where(
          :uid => attributes[:uid],
          :provider => attributes[:provider],
          :realm_id => target_identity.try(:realm_id)
        ).first
        if account.identity_id == target_identity.id
          # Fine. We are declaring a potential update on an existing account. Update in place
          account.attributes = attributes
          account.save!
          return account
        else
          # Oh noes! A real, unresolvable conflict!
          raise InUseError.new("Account is bound to a different identity", :identity_id => account.identity_id)
        end
      end
    end

    # Creates or updates an account from auth data as provided by
    # omniauth. An existing identity or a realm must be provided
    # see https://github.com/intridea/omniauth/wiki/Auth-Hash-Schema for an overview of the data omniauth provides
    # in the options. E.g.:
    #     Account.declare_with_omniauth(auth, :realm => current_realm) # creates a new user
    #     Account.declare_with_omniauth(auth, :identity => current_identity) # attaches an account to an existing identity
    # If the account was previously attached to an identity, an InUseError exception will be raised.
    def declare_with_omniauth(auth_data, options = {})
      raise ArgumentError, "Identity or realm must be specified" unless (options[:realm] || options[:identity])
      # Attach to specified identity?
      identity = options[:identity]
      # Use an implied identity?
      identity ||= Account.where(
        :realm_id => options[:realm].id,
        :provider => auth_data['provider'],
        :uid => auth_data['uid']).first.try(:identity)
      # Create a new identity!
      identity ||= Identity.create!(:realm => options[:realm])

      account = declare!(
        :provider => auth_data['provider'],
        :uid => auth_data['uid'],
        :realm_id => options[:realm].try(:id) || identity.realm.id,
        :identity =>     identity,
        :token =>        auth_data['credentials']['token'],
        :secret =>       auth_data['credentials']['secret'],
        :nickname =>     auth_data['info']['nickname'],
        :name =>         auth_data['info']['name'],
        :location =>     auth_data['info']['location'],
        :image_url =>    auth_data['info']['image'],
        :description =>  auth_data['info']['description'],
        :email =>        auth_data['info']['email'],
        :profile_url =>  (auth_data['info']['urls'] || {})['Twitter']
      )
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

  # Computes one or more hashes of the permanent components of the account 
  # data, which can function as a fingerprint to recognize future duplicate
  # accounts. This makes it possible to ban accounts purely based on
  # fingerprints.
  def fingerprints
    # Note: Fingerprints must always be lowercase due to current limitations in 
    # ar-tsvectors and Postgres indexing.
    digest = Digest::SHA256.new
    digest.update(self.provider.to_s)
    digest.update(self.uid.to_s)
    [digest.digest.unpack("H*")[0].hex.to_s(36)]
  end

  private

  # Pick a primary account for the identity
  def update_identity_primary_account
    return unless self.identity
    self.identity.ensure_primary_account
    self.identity.save!
  end

  # Clear primary_account field if it points to self.
  def reset_identity_primary_account
    return unless self.identity
    if self.primary?
      self.identity.primary_account = nil
      self.identity.save!
    end
  end

  def invalidate_cache
    self.identity.invalidate_cache if self.identity
  end

  def infer_realm
    self.realm = self.identity.try(:realm) if self.identity
  end

end
