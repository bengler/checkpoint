class Identity < ActiveRecord::Base

  class NotAuthorized < Exception; end

  has_many :accounts, :dependent => :destroy,
    :after_add => :update_fingerprints_from_account!
  has_many :sessions, :dependent => :destroy
  belongs_to :primary_account, :class_name => 'Account'
  belongs_to :realm

  before_create :initialize_last_seen
  before_destroy :invalidate_cache
  before_update :invalidate_cache

  validates_presence_of :realm_id

  ts_vector :tags
  ts_vector :fingerprints

  # Make sure fingerprints cannot be assigned directly
  private :fingerprints=

  scope :having_realm, lambda { |realm|
    where(:realm_id => realm.id)
  }
  scope :anonymous, -> {
    where("primary_account_id is null")
  }
  scope :not_seen_for_more_than_days, lambda { |days|
    where("last_seen_on is not null and (current_date - last_seen_on) > ?", days)
  }

  def root?
    god && realm.label == 'root'
  end

  def ensure_primary_account
    self.primary_account ||= accounts.order('created_at').first
  end

  def provisional?
    primary_account.nil? and accounts.empty?
  end

  def self.cache_key(id)
    "identity:#{id}"
  end

  def self.id_from_key(cache_key)
    cache_key.match(/\d+$/).to_s.to_i
  end

  def cache_key
    self.class.cache_key(id)
  end

  def self.cached_find_by_id(id)
    if attributes = $memcached.get(cache_key(id))
      return Identity.instantiate(Yajl::Parser.parse(attributes))
    else
      identity = Identity.find_by_id(id)
      return nil unless identity
      $memcached.set(cache_key(id), identity.attributes.to_json)
      identity.readonly!
      return identity
    end
  end

  def self.cached_find_all_by_id(ids)
    ids.map!(&:to_i)
    keys = ids.map{ |id| Identity.cache_key(id)}
    result =  Hash[
      $memcached.get_multi(*keys).map do |key, value|
        identity = Identity.instantiate(Yajl::Parser.parse(value))
        identity.readonly!
        [id_from_key(key), identity]
      end
    ]
    uncached = (ids-result.keys)
    Identity.find_all_by_id(uncached).each do |identity|
      $memcached.set(identity.cache_key, identity.attributes.to_json) if identity
      result[identity.id] = identity
    end
    ids.map{|id| result[id]}
  end

  def self.find_by_session_key(session_key)
    cached_find_by_id(Session.identity_id_for_session(session_key))
  end

  def self.find_by_query(query)
    if query[0] == '"' and query[-1] == '"'
      query.gsub!('"', '')
    else
      query = "%#{query.gsub(/\s+/, '%')}%"
    end
    Identity.includes(:accounts).where(
      "accounts.name ILIKE ? OR " <<
      "accounts.nickname ILIKE ? OR " <<
      "accounts.email ILIKE ?", query, query, query)
  end

  def mark_as_seen
    today = Date.today
    if self.last_seen_on != today
      self.last_seen_on = today
      self.save(:validate => false)
    end
  end

  def invalidate_cache
    $memcached.delete(self.cache_key)
  end

  def update_fingerprints_from_account!(account)
    if account and (fingerprints = account.fingerprints)
      self.send(:fingerprints=, fingerprints | self.fingerprints)
      save(validate: false) unless new_record?
    end
  end

  private

    def initialize_last_seen
      self.last_seen_on ||= Time.now.to_date
    end

end
