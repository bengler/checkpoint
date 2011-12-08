class CheckpointV1 < Sinatra::Base

  post '/realms' do
    check_root_credentials
    @realm = Realm.create!(params[:realm])
    Domain.create!(params[:domain].merge(:realm => @realm))
    @identity = Identity.create!(:realm => @realm, :god => true)
    @session = Session.create!(:identity => @identity)
    render :rabl, :realm, :format => :json
  end

  get '/realms' do
    { realms: Realm.all.map(&:label) }.to_json
  end

  get '/realms/:label' do |label|
    @realm = find_realm_by_label(label)
    if current_identity && current_identity.root?
      @sessions = @realm.god_sessions
    end
    render :rabl, :realm, :format => :json
  end
end
