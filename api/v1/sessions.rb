class CheckpointV1 < Sinatra::Base
  get '/sessions/:key' do
    @identity = Identity.find(SessionManager.identity_id_for_session(params[:key]))
    @identity == current_identity or check_god_credentials(@identity.realm_id)
    render :rabl, :identity, :format => :json
  end

  post '/sessions' do
    identity = Identity.find_by_id(params[:identity_id])
    identity ||= current_identity
    halt 404, "No identity found" unless identity
    identity == current_identity or check_god_credentials(identity.realm_id)
    expire = (params[:expire] == 'never') ? nil : (params[:expire].try(:to_i) || 1.hour)
    { session: SessionManager.new_session(identity.id, :expire => expire), identity_id: identity.id }.to_json
  end

  delete '/sessions/:key' do
    identity = Identity.find(SessionManager.identity_id_for_session(params[:key]))
    identity == current_identity or check_god_credentials(identity.realm_id)
    SessionManager.kill_session(params[:key])
    { identity_id: identity.id }.to_json
  end

  post '/sessions/:key/persist' do
    identity = Identity.find(SessionManager.identity_id_for_session(params[:key]))
    identity == current_identity or check_god_credentials(identity.realm_id)
    SessionManager.persist_session(params[:key])
    { session: params[:key] }
  end
end
