class CheckpointV1 < Sinatra::Base

  get '/realms/:label/domains/:name' do
    @domain = Domain.find_by_name(params[:name])
    render :rabl, :domain, :format => :json
  end

  post '/realms/:label/domains' do
    realm = find_realm_by_label(params[:label])
    check_god_credentials(realm.id)
    @domain = Domain.find_by_name(params[:name])        
    halt 403, "Domain was connected to realm '#{@domain.realm.label}'" if @domain && @domain.realm != realm
    @domain ||= Domain.create!(:name => params[:name], :realm => realm)
    "Ok"
  end

  delete '/realms/:label/domains/:name' do
    @domain = Domain.find_by_name(params[:name])
    halt 403, "Domain is connected to '#{@domain.realm.label}'" unless @domain.realm.label == params[:label]
    check_god_credentials(@domain.realm.id)
    @domain.destroy
    "Ok"
  end

end
