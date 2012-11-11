class CheckpointV1 < Sinatra::Base

  # Create a realm
  #
  # @param [Hash] realm the attributes of the realm
  # @param [Hash] domain the attributes of the domain
  # @return [JSON] the realm, along with a (god) identity and a session key
  post '/realms' do
    check_root_credentials
    realm = Realm.create!(params[:realm])
    Domain.create!(params[:domain].merge(:realm => realm))
    identity = Identity.create!(:realm => realm, :god => true)
    new_session = Session.create!(:identity => identity)
    [201, pg(:realm, :locals => {:realm => realm, :identity => identity, :sessions => [new_session]})]
  end

  # List all realms
  #
  # @return [JSON] A list of the realms in the system (label only)
  get '/realms' do
    { realms: Realm.all.map(&:label) }.to_json
  end

  # Get a realm
  #
  # @param [String] label the realm
  # @returns [JSON] the realm. Includes god sessions for the realm if current id is root.
  get '/realms/:label' do |label|
    realm = find_realm_by_label(label)
    if current_identity && current_identity.root?
      sessions = realm.god_sessions
    end
    pg :realm, :locals => {:realm => realm, :identity => nil, :sessions => sessions}
  end
  
  # Get a realm by its domain name (Oh, inverted world)
  #
  # @param [String] name the domain name
  # @return [JSON] the realm
  get '/domains/:name/realm' do |name|
    domain = Domain.find_by_name(name)
    halt 404, "Not found" unless domain
    pg :realm, :locals => {:realm => domain.realm, :identity => nil, :sessions => nil}
  end
  
end
