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
    identities = Identity.joins(:identity_fingerprints).
      where(:realm_id => current_realm.id).
      where("identity_fingerprints.fingerprint in (?)", fingerprints.split(','))
    pg :identities, :locals => { :identities => identities }
  end
end
