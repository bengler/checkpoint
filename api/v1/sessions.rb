class CheckpointV1 < Sinatra::Base

  # @apidoc
  # Get metadata for a session.
  #
  # @note Only gods may inspect the sessions of other identities.
  # @category Checkpoint/Realms
  # @path /api/checkpoint/v1/sessions/:key
  # @example /api/checkpoint/v1/sessions/bj1vjkijoz895miad1at1m3u7a6bvrdzzikyty8m0vien2i0y9uysr6hg0zzudymxu2by7qxthv5fjgd700trd3snlfq0fzrihh
  # @http GET
  # @required [String] key The key of the session.
  # @status 200 [JSON] Session metadata.

  get '/sessions/:key' do |id|
    @session = Session.find_by_key(id)
    halt 200, {'Content-Type' => 'application/json'}, "{}" unless @session
    unless @session.identity == current_identity
      check_god_credentials(@session.identity.realm_id)
    end
    pg :session, :locals => {:session => @session}
  end

  post '/sessions/:key' do |id|
    check_god_credentials(current_identity.try(:realm_id))
    @session = Session.find_by_key(id)
    @session ||= Session.new(:key => id)
    @session.identity_id = params[:identity_id]
    @session.save!
    halt 204
  end


  # @apidoc
  # Create a session.
  #
  # @note Only gods may create sessions for other identities.
  # @category Checkpoint/Realms
  # @path /api/checkpoint/v1/sessions
  # @example /api/checkpoint/v1/sessions
  # @http POST
  # @required [Integer] identity_id The id of the identity to create a session for.
  # @status 200 [JSON] Session metadata.

  post '/sessions' do
    identity = Identity.find_by_id(params[:identity_id])
    if identity
      check_god_credentials(identity.realm_id)
      @current_session = new_session
    end
    identity ||= current_identity
    halt 500, "Identity not found" unless identity

    log_in(identity)
    pg :session, :locals => {:session => current_session}
  end

  # @apidoc
  # Delete a session key.
  #
  # @note Only gods may delete sessions of other identities.
  # @description Deleting a session key effectively logs out the user with that key.
  # @category Checkpoint/Realms
  # @path /api/checkpoint/v1/sessions/:key
  # @example /api/checkpoint/v1/sessions/bj1vjkijoz895miad1at1m3u7a6bvrdzzikyty8m0vien2i0y9uysr6hg0zzudymxu2by7qxthv5fjgd700trd3snlfq0fzrihh
  # @http DELETE
  # @required [Integer] key The hash of the session.
  # @status 200 [JSON] Session metadata.

  delete '/sessions/:key' do
    session = Session.find_by_key(params[:key])
    halt 500, "No such session" unless session
    unless session.identity == current_identity
      check_god_credentials(session.identity.realm_id)
    end
    session.destroy
    halt 204
  end

end
