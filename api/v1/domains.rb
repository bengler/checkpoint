class CheckpointV1 < Sinatra::Base

  # Get a domain by its domain name
  #
  # @param [String] name the domain name
  # @return [JSON] the domain
  get '/domains/:name' do
    domain = Domain.find_by_name(params[:name])
    halt 404, "Not found" unless domain
    pg :domain, :locals => {:domain => domain}
  end

  # Get a list of domains connected to a realm
  #
  # @param [String] label the label of the realm.
  # @return [JSON] list of domains
  get '/realms/:label/domains' do |label|
    domains = Realm.find_by_label(label).domains
    pg :domains, :locals => {:domains => domains}
  end

  # Get a domain
  #
  # @param [String] label the label of the realm. (can be '*')
  # @param [String] name the domain name
  # @return [JSON] the domain
  get '/realms/:label/domains/:name' do
    domain = Domain.find_by_name(params[:name])
    halt 404, "Not found" unless domain
    pg :domain, :locals => {:domain => domain}
  end

  # Add a domain to a realm
  #
  # @param [String] label the realm
  # @return [JSON] the domain
  post '/realms/:label/domains' do
    realm = find_realm_by_label(params[:label])
    check_god_credentials(realm.id)
    domain = Domain.find_by_name(params[:name])
    halt 403, "Domain was connected to realm '#{domain.realm.label}'" if domain && domain.realm != realm
    domain ||= Domain.create!(:name => params[:name], :realm => realm)
    pg :domain, :locals => {:domain => domain}
  end

  # Delete a domain from a realm
  #
  # @param [String] label the realm
  # @param [String] name the domain name
  # @return [Nothing]
  delete '/realms/:label/domains/:name' do
    domain = Domain.find_by_name(params[:name])
    halt 403, "Domain is connected to '#{domain.realm.label}'" unless domain.realm.label == params[:label]
    check_god_credentials(domain.realm.id)
    domain.destroy
    halt 204
  end

end
