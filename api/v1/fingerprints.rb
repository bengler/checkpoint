class CheckpointV1 < Sinatra::Base

  # @apidoc
  # Get identities by fingerprints
  #
  # @category Checkpoint/Fingerprints
  # @path /api/checkpoint/v1/fingerprints/:fingerprints/identities
  # @example /api/checkpoint/v1/fingerprints/3eww7uspsy770ohuzoui9wb038up99ci79jz94dpsi6263xi1b/identities
  # @http GET
  # @required [String] fingerprints A comma-separated list of fingerprints
  # @status 200 [JSON] A collection of identities

  get '/fingerprints/:fingerprints/identities' do |fingerprints|
    identities = Identity.where(:realm_id => current_realm.id).
      where(["fingerprints @@ ?", fingerprints.split(',').join('|')])
    pg :identities, :locals => { :identities => identities }
  end
  
  # @apidoc
  # Post a new fingerprint to an identity
  #
  # @category Checkpoint/Fingerprints
  # @path /api/checkpoint/v1/identities/:identity_id/fingerprints
  # @example /api/checkpoint/v1/identities/1337/fingerprints
  # @http POST
  # @required [Array] fingerprints An array of strings to add as fingerprints
  # @status 200 [JSON] The identity object containing the complete list of fingerprints, including the newly added ones

  post '/identities/:identity_id/fingerprints' do |identity_id|
    require_god
    identity = Identity.find(identity_id)
    identity.add_fingerprints!(request['fingerprints'])
    pg :identity, :locals => { :identity => identity }
  end
end