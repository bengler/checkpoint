class CheckpointV1 < Sinatra::Base

  # @apidoc
  # Check if current session is banned on a given path
  # Returns a json object with the boolean property `banned`, and if this is true, the `path` property containst the
  # path the user is banned from
  # @category Checkpoint/Bannings
  # @param path the path to check if current session identity is banned from
  # @path /api/checkpoint/v1/bannings/mine/:path
  # @http GET
  get "/bannings/mine/:path" do |path|
    require_identity
    banned_path = Banning.banned_path(path: path, identity: current_identity.try(:id))

    result = banned_path ? {banned: true, path: banned_path} : {banned: false}

    [200, result.to_json]
  end

  # @apidoc
  # Get all effective bans for a given path
  #
  # @category Checkpoint/Bannings
  # @param identity_id Filter list by an identity. This can be used to quickly determine 
  #   if an identity is banned for the given path.
  # @path /api/checkpoint/v1/bannings/:path
  # @http GET
  get "/bannings/:path" do |path|
    require_action_allowed(:moderate, "post.any:#{path}", :default => false)
    bannings = Banning.by_path("^#{path}")
    if params[:identity_id]
      identity = Identity.where(id: params[:identity_id]).first
      halt 404, "No such identity" unless identity
      check_path_in_realm(path, identity.realm)
      bannings = bannings.where("fingerprint in (?)", identity.fingerprints)
    end

    pg :bannings, locals: {bannings: bannings}
  end

  # @apidoc
  # Make it so the given identity is banned from the provided path. Will replace any more specific
  # bans shadowed by this ban. Will not do anything if a more general, equivalent ban is allready in place.
  # Returns a list of the bans that are actually in effect to comply with this directive.
  #
  # @category Checkpoint/Bannings
  # @path /api/checkpoint/v1/bannings/:path/identities/:identity
  # @http PUT

  put "/bannings/:path/identities/:identity" do |path, identity|
    require_action_allowed(:moderate, "post.any:#{path}", :default => false)
    identity = Identity.find_by_id(identity)
    halt 404, "No such identity" unless identity
    halt 400, "Unable to ban identity. No fingerprints!" if identity.fingerprints.empty?

    bannings = identity.fingerprints.map do |fingerprint|
      Banning.declare!(:path => path, :fingerprint => fingerprint)
    end

    response.status = 201
    pg :bannings, :locals => {:bannings => bannings}
  end

  # @apidoc
  # Delete any effective bans that preclude the given identity from accessing the given path. May delete
  # a more general ban if required. Returns all bans that were removed.
  #
  # @category Checkpoint/Bannings
  # @path /api/checkpoint/v1/bannings/:path/identities/:identity
  # @http DELETE

  delete "/bannings/:path/identities/:identity" do |path, identity|
    require_action_allowed(:moderate, "post.any:#{path}", :default => false)
    identity = Identity.find_by_id(identity)
    halt 404, "No such identity" unless identity

    bannings = Banning.where("fingerprint in (?)", identity.fingerprints).by_path("^#{path}")
    bannings.destroy_all

    pg :bannings, :locals => {:bannings => bannings}
  end

  def check_path_in_realm(path, realm = current_realm)
    unless path.split('.').first == realm.label
      halt 403, "The path #{path} is not in correct realm (#{realm.label})"
    end
  end

end