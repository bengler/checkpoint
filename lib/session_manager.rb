module SessionManager

  COOKIE_NAME = "checkpoint.session"
  DEFAULT_SESSION_EXPIRY = 6.months

  # A somewhat hacky way to load the identity rabl template
  # outside a controller for use in 'update_identity_record'
  @@identity_template = Rabl::Engine.new(
    File.read(Sinatra::Application.root+'/api/v1/views/identity.rabl'), 
    :format => 'json')


  def self.connect(redis = nil)
    @redis = redis || Redis.new
  end

  def self.random_key
    # The number of possible keys is approximately the number of atoms
    # in the observable universe multiplied by the number of atoms in
    # the observable universe.
    srand
    rand(2**512).to_s(36)
  end

  def self.new_session(identity_id, options = {})
    key = random_key
    redis_key = "session:#{key}"
    @redis.set(redis_key, identity_id)
    @redis.expire(redis_key, options[:expire] || DEFAULT_SESSION_EXPIRY)
    key
  end

  def self.update_identity_record(identity)
    template_scope = Object.new; template_scope.instance_variable_set(:@identity, identity)
    @redis.set("identity:#{identity.id}", 
      @@identity_template.render(template_scope, {}))
  end

  def self.identity_id_for_session(key)
    return nil unless key
    identity_id = @redis.get("session:#{key}")
    identity_id.to_i unless identity_id.nil?
  end

  def self.identity_for_session(key)
    Identity.find_by_id(identity_id_for_session(key))
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