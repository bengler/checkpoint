class Identity < ActiveRecord::Base

  class NotAuthorized < Exception; end

  has_many :accounts, :dependent => :destroy  
  belongs_to :primary_account, :class_name => 'Account'
  belongs_to :realm
  
  before_create :initialize_last_seen
  before_destroy :invalidate_cache, :destroy_sessions
  before_update :invalidate_cache

  validates_presence_of :realm_id

  scope :anonymous, where("primary_account_id is null")
  scope :not_seen_for_more_than_days, lambda { |days|
    where("last_seen_at is not null and (current_date - last_seen_at) > ?", days)
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

  def mark_as_seen
    update_count = Identity.update_all(
      "last_seen_at = current_date", "id = #{self.id} and (last_seen_at != current_date or last_seen_at is null)")
    invalidate_cache if update_count > 0
  end

  def invalidate_cache
    $memcached.delete(self.cache_key)
  end

  private

  def initialize_last_seen
    self.last_seen_at ||= Time.now.to_date
  end

  def destroy_sessions
    Session.destroy_all_for_identity(self)
  end

end
