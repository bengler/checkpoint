class Session < ActiveRecord::Base

  belongs_to :identity

  before_save :ensure_key
  after_destroy :invalidate_cache
  after_save :invalidate_cache

  COOKIE_NAME = "checkpoint.session".freeze

  DEFAULT_EXPIRY = Time.parse("2100-01-01").freeze

  def self.cache_key(key)
    "session:#{key}"
  end

  def cache_key
    self.class.cache_key(key)
  end

  def self.random_key
    # The number of possible keys is approximately the number of atoms
    # in the observable universe multiplied by the number of atoms in
    # the observable universe.
    SecureRandom.random_number(2 ** 512).to_s(36)
  end

  def self.identity_id_for_session(session_key)
    return $memcached.fetch(cache_key(session_key)) {
      Session.connection.select_value(
        "select identity_id from sessions where key = '#{session_key}'")
    }.try(:to_i)
  end

  def self.destroy_by_key(session_key)
    Session.find_by_key(session_key).try(:destroy)
  end

  def invalidate_cache
    $memcached.delete(self.cache_key)
  end

  private

    def ensure_key
      self.key ||= Session.random_key
    end

end