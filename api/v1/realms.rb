class CheckpointV1 < Sinatra::Amedia::Base


  # @apidoc
  # Create a realm.
  #
  # @category Checkpoint/Realms
  # @path /api/checkpoint/v1/realms
  # @example /api/checkpoint/v1/realms
  # @http POST
  # @required [Hash] realm The attributes of the realm.
  # @required [Hash] domain The attributes of the primary domain.
  # @status 201 [JSON] The realm, along with a (god) identity and a session key.

  post '/realms' do
    check_root_credentials
    realm = Realm.create!(params[:realm])
    Domain.create!(params[:domain].merge(:realm => realm))
    identity = Identity.create!(:realm => realm, :god => true)
    new_session = Session.create!(:identity => identity)
    [201, pg(:realm, :locals => {:realm => realm, :identity => identity, :sessions => [new_session]})]
  end

  # @apidoc
  # List all realms.
  #
  # @category Checkpoint/Realms
  # @path /api/checkpoint/v1/realms
  # @example /api/checkpoint/v1/realms
  # @http GET
  # @status 200 [JSON] the realms

  get '/realms' do
    { realms: Realm.all.map(&:label) }.to_json
  end

  # @apidoc
  # Get metadata for a realm.
  #
  # @category Checkpoint/Realms
  # @path /api/checkpoint/v1/realms/:label
  # @example /api/checkpoint/v1/realms/acme
  # @http GET
  # @status 200 [JSON] The realm. Includes god sessions for the realm if current id is root.

  get '/realms/:label' do |label|
    realm = find_realm_by_label(label)
    if current_identity && current_identity.root?
      sessions = realm.god_sessions
    end
    pg :realm, :locals => {:realm => realm, :identity => nil, :sessions => sessions}
  end

  # @apidoc
  # Get a realm by its domain name. (Oh, inverted world!)
  #
  # @category Checkpoint/Realms
  # @path /api/checkpoint/v1/domains/:name/realm
  # @example /api/checkpoint/v1/domains/:name/realm
  # @http GET
  # @status 200 [JSON] The realm.

  get '/domains/:name/realm' do |name|
    domain = Domain.resolve_from_host_name(name)
    halt 404, "Not found" unless domain
    pg :realm, :locals => {:realm => domain.realm, :identity => nil, :sessions => nil}
  end

end
