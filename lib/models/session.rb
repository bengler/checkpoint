class Session < ActiveRecord::Base
  belongs_to :identity
  before_save :create_key
  before_destroy :uncache

  COOKIE_NAME = "checkpoint.session"

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
    srand
    rand(2**512).to_s(36)
  end

  def self.identity_id_for_session(session_key)
    result = $memcached.fetch(cache_key(session_key)) do
      Session.connection.select_value("select identity_id from sessions where key = '#{session_key}'")
    end
    return nil unless result
    result.to_i
  end

  def self.destroy_by_key(session_key)
    Session.find_by_key(session_key).try(:destroy)
  end

  def self.destroy_all_for_identity(identity)
    Session.where("identity_id = ?", identity).map(&:destroy)
  end

  def uncache
    $memcached.delete(self.cache_key)
  end

  private

  def create_key
    self.key ||= Session.random_key
  end


end