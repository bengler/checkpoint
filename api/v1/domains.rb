class CheckpointV1 < Sinatra::Base

  # @apidoc
  # Get metadata for a domain.
  #
  # @category Checkpoint/Domains
  # @path /api/checkpoint/v1/domains/:name
  # @http GET
  # @required [String] name The domain name.
  # @example /api/checkpoint/v1/domains/acme.org
  # @status 404 Not found.
  # @status 200 [JSON]

  get '/domains/:name' do |name|
    domain = Domain.find_by_name(name)
    halt 404, "Not found" unless domain
    pg :domain, :locals => {:domain => domain}
  end

  # @deprecated Use /domains/:name instead.
  get '/realms/:label/domains/:name' do
    domain = Domain.find_by_name(params[:name])
    halt 404, "Not found" unless domain
    pg :domain, :locals => {:domain => domain}
  end

  # @apidoc
  # Add a domain to a realm.
  #
  # @description To use checkpoint on a given domain it must be added to a realm first.
  # @note Only gods of the realm may do this.
  # @category Checkpoint/Domains
  # @path /api/checkpoint/v1/realms/:label/domains
  # @http POST
  # @required [String] label The realm.
  # @required [String] name The domain name.
  # @example /api/checkpoint/v1/realms/acme?name=acme.org
  # @status 403 The domain is connected to a different realm.
  # @status 409 You are not a god in this realm.
  # @status 200 [JSON]

  post '/realms/:label/domains' do
    realm = find_realm_by_label(params[:label])
    check_god_credentials(realm.id)
    domain = Domain.find_by_name(params[:name])
    halt 403, "Domain was connected to realm '#{domain.realm.label}'" if domain && domain.realm != realm
    domain ||= Domain.create!(:name => params[:name], :realm => realm)
    pg :domain, :locals => {:domain => domain}
  end

  # @apidoc
  # Delete a domain from a realm.
  #
  # @note Only gods of the realm may do this.
  # @category Checkpoint/Domains
  # @path /api/checkpoint/v1/realms/:label/domains/:name
  # @http DELETE
  # @required [String] label The realm.
  # @required [String] name The domain name.
  # @example /api/checkpoint/v1/realms/acme/domains/acme.org
  # @status 403 The domain is connected to a different realm.
  # @status 409 You are not a god in this realm.
  # @status 204 Ok.

  delete '/realms/:label/domains/:name' do
    domain = Domain.find_by_name(params[:name])
    halt 403, "Domain is connected to '#{domain.realm.label}'" unless domain.realm.label == params[:label]
    check_god_credentials(domain.realm.id)
    domain.destroy
    halt 204
  end

end
