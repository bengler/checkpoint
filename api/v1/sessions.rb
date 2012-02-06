# TODO: add petroglyph templates for session.

class CheckpointV1 < Sinatra::Base
  # Get a session
  #
  # @param [String] key  the session key
  # @return [JSON] json containing the session key and the identity id
  get '/sessions/:key' do |id|
    @session = Session.find_by_key(id)
    halt 200, "{}" unless @session
    @session.identity == current_identity or check_god_credentials(@session.identity.realm_id)
    { session: {id: @session.key, identity_id: @session.identity_id }}.to_json
  end

  # Create a session
  #
  # @param [String] identity_id the id of the identity requesting a session (optional). Defaults to current id.
  # @return [JSON] json containing the session key and the identity id
  post '/sessions' do
    identity = Identity.find_by_id(params[:identity_id])
    identity ||= current_identity
    halt 500, "Identity not found" unless identity
    identity == current_identity or check_god_credentials(identity.realm_id)
    expire = (params[:expire] == 'never') ? nil : (params[:expire].try(:to_i) || 1.hour)
    { session: {id: Session.create!(:identity => identity).key, identity_id: identity.id }}.to_json
  end

  # Delete a session key
  #
  # @param [String] key the session key for the session to be deleted.
  # @return [Nothing]
  delete '/sessions/:key' do
    session = Session.find_by_key(params[:key])
    halt 500, "No such session" unless session
    session.identity == current_identity or check_god_credentials(session.identity.realm_id)
    session.destroy
    halt 204
  end
end
