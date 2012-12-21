class CheckpointV1 < Sinatra::Base

  # @apidoc
  # Get all effective bans for a given path
  #
  # @category Checkpoint/Bannings
  # @path /api/checkpoint/v1/bannings/:path
  # @http GET

  get "/bannings/:path" do |path|
    check_god_credentials
    unless path.split('.').first == current_realm.label
      halt 403, "The path #{path} is not in this realm (#{current_realm.label})"
    end
    bannings = Banning.by_path("^#{path}")

    pg :bannings, :locals => { :bannings => bannings }
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
    identity = Identity.find_by_id(identity)
    halt 404, "No such identity" unless identity
    halt 403, "Identity and path is in different realms" unless path.split('.').first == identity.realm.label
    check_god_credentials(identity.realm.id)
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
    identity = Identity.find_by_id(identity)
    halt 404, "No such identity" unless identity
    halt 400, "Identity and path is of different realms" unless path.split('.').first == identity.realm.label
    check_god_credentials(identity.realm.id)

    bannings = Banning.where(["fingerprint in (?)", identity.fingerprints]).by_path("^#{path}")
    bannings.map(&:destroy)

    pg :bannings, :locals => {:bannings => bannings}
  end

end