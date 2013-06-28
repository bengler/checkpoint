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
    domain = Domain.resolve_from_host_name(name)
    halt 404, "Not found" unless domain
    pg :domain, :locals => {:domain => domain}
  end

  # @deprecated Use /domains/:name instead.
  get '/realms/:label/domains/:name' do
    domain = Domain.resolve_from_host_name(params[:name])
    halt 404, "Not found" unless domain
    pg :domain, :locals => {:domain => domain}
  end

  # @apidoc
  # Test if a domain associated with Checkpoint trusts an abritary domain
  #
  # @category Checkpoint/Domains
  # @path /api/checkpoint/v1/domains/:name/allows/:origin
  # @http GET
  # @required [String] name The domain name associated with Checkpoint.
  # @required [String] origin The abritary domain name to test against.
  # @example /api/checkpoint/v1/domains/acme.org/allows/pinshing.com
  # @status 404 No associated domain name.
  # @status 200 [JSON] allowed: true/false

  get '/domains/:name/allows/:origin' do |name, origin|
    domain = Domain.resolve_from_host_name(name)
    halt 404, "No associated domain name" unless domain
    content_type :json
    {allowed: domain.allow_origin?(origin)}.to_json
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
  # @status 201 [JSON]

  post '/realms/:label/domains' do
    realm = find_realm_by_label(params[:label])
    check_god_credentials(realm.id)
    domain = Domain.find_by_name(params[:name])
    halt 403, "Domain was connected to realm '#{domain.realm.label}'" if domain && domain.realm != realm
    domain ||= Domain.create!(:name => params[:name], :realm => realm)
    [201, pg(:domain, :locals => {:domain => domain})]
  end

  # @apidoc
  # Add an origin host to a domain.
  #
  # @description Add a host to the domain's origins
  # @note Only gods of the realm may do this.
  # @category Checkpoint/Domains
  # @path /api/checkpoint/v1/realms/:label/domains/:name/origins
  # @http POST
  # @required [String] label The realm.
  # @required [String] name The domain name.
  # @required [String] origin The origin domain name.
  # @example /api/checkpoint/v1/realms/acme/acme.org/origins
  # @status 403 The domain is connected to a different realm.
  # @status 409 You are not a god in this realm.
  # @status 201 OK

  post '/realms/:label/domains/:name/origins' do |label, name|
    halt 400, "param origin missing" unless params[:origin]
    realm = find_realm_by_label(label)
    check_god_credentials(realm.id)
    domain = Domain.find_by_name(name)
    halt 403, "Domain is connected to realm '#{domain.realm.label}'" if domain && domain.name != name
    domain.add_origin(params[:origin])
    [201, pg(:domain, :locals => {:domain => domain})]
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
    domain = Domain.resolve_from_host_name(params[:name])
    halt 403, "Domain is connected to '#{domain.realm.label}'" unless domain.realm.label == params[:label]
    check_god_credentials(domain.realm.id)
    domain.destroy
    halt 204
  end

  # @apidoc
  # Delete an origin host from a domain.
  #
  # @note Only gods of the realm may do this.
  # @category Checkpoint/Domains
  # @path /api/checkpoint/v1/realms/:label/domains/:name/origins/:origin
  # @http DELETE
  # @required [String] label The realm.
  # @required [String] name The domain name.
  # @required [String] origin The origin domain name.
  # @example /api/checkpoint/v1/realms/acme/domains/acme.org/origins/pinshing.com
  # @status 403 The domain is connected to a different realm.
  # @status 409 You are not a god in this realm.
  # @status 204 Ok.

  delete '/realms/:label/domains/:name/origins/:origin' do |label, name, origin|
    domain = Domain.resolve_from_host_name(name)
    halt 403, "Domain is connected to '#{domain.realm.label}'" unless domain.realm.label == label
    check_god_credentials(domain.realm.id)
    domain.remove_origin(origin)
    halt 204
  end
end
