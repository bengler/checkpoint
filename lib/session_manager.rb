module SessionManager

  COOKIE_NAME = "checkpoint.identity"

  def self.connect(redis = nil)
    @redis = redis || Redis.new
  end

  def self.random_key
    rand(2**512).to_s(36)
  end

  def self.new_session(identity_id)
    key = random_key
    @redis.set("session:#{key}", identity_id)
    key
  end

  def self.identity_id_for_session(key)
    return nil unless key
    identity_id = @redis.get("session:#{key}")
    identity_id.to_i unless identity_id.nil?
  end

  def self.redis
    @redis
  end

end