module SessionManager

  COOKIE_NAME = "checkpoint.identity"

  def self.connect(redis = nil)
    @redis = redis || Redis.new
  end

  def self.random_key
    # The number of possible keys is approximately the number of atoms
    # in the observable universe multiplied by the number of atoms in
    # the observable universe.
    rand(2**512).to_s(36)
  end

  def self.new_session(identity_id, options = {})
    key = random_key
    redis_key = "session:#{key}"
    @redis.set(redis_key, identity_id)
    @redis.expire(redis_key, options[:expire] || 6.months)
    key
  end

  def self.identity_id_for_session(key)
    return nil unless key
    identity_id = @redis.get("session:#{key}")
    identity_id.to_i unless identity_id.nil?
  end

  def self.kill_session(key)
    @redis.del("session:#{key}")
  end

  def self.persist_session(key)
    @redis.persist("session:#{key}")
  end

  def self.redis
    @redis
  end

end