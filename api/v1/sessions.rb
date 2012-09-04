# TODO: add petroglyph templates for session.
class CheckpointV1 < Sinatra::Base

  # Get a session
  #
  # @param [String] key  the session key
  # @return [JSON] json containing the session key and the identity id
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

  # Create a session
  #
  # @param [String] identity_id the id of the identity requesting a session (optional). Defaults to current id.
  # @return [JSON] json containing the session key and the identity id
  post '/sessions' do
    identity = Identity.find_by_id(params[:identity_id])
    identity ||= current_identity
    halt 500, "Identity not found" unless identity
    unless identity == current_identity
      check_god_credentials(identity.realm_id)
    end
    log_in(identity)
    pg :session, :locals => {:session => current_session}
  end

  # Delete a session key
  #
  # @param [String] key the session key for the session to be deleted.
  # @return [Nothing]
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
