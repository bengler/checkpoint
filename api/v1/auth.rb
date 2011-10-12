class CheckpointV1 < Sinatra::Base

  get '/:realm/auth/:provider' do
    realm = Realm.find_by_label(params[:realm])
    halt 404, "Unknown realm #{params[:realm]}" unless realm
    session[:realm] = params[:realm]
    redirect to("/auth/#{params[:provider]}")
  end

  # This is called directly by Omniauth to allow us to setup
  # the strategy. Unfortunately I did not find a way to
  # provide the realm with the url, so it is passed through
  # the session. Yuck!
  get '/auth/:provider/setup' do
    strategy = request.env['omniauth.strategy']
    realm = Realm.find_by_label(session[:realm])
    service_keys = realm.keys_for(params[:provider].to_sym)

    if strategy.respond_to?(:consumer_key)
      strategy.consumer_key = service_keys.consumer_key
      strategy.consumer_secret = service_keys.consumer_secret
    elsif strategy.respond_to?(:client_id)
      strategy.client_id = service_keys.client_id
      strategy.client_secret = service_keys.client_secret
    else
      halt 500, "Invalid strategy for provider: #{params[:provider]}"
    end

    strategy.options[:scope] = service_keys.scope if service_keys.scope

    # NOTE: Additional params can be set here like this:
    strategy.options[:realm] = realm.label

    strategy.options[:callback] = api_path("/#{realm.label}/auth/#{params[:provider]}/callback")

    # TODO: Add detection of device to wisely choose whether we should ask for
    # touch interface from facebook.
    # strategy.options[:display] = "touch" if params[:provider] == "facebook"

    "Setup complete."
  end

  get "/auth/:provider/terminate" do
    # TODO: Find realm through authentication
    realm = Realm.find_by_label(params[:realm])

    auth = current_identity.accounts.where(
      :realm_id => realm.id, :provider => params[:provider])
      return halt 404, "No such authentication found" if auth.empty?
      auth.map(&:destroy)

      logger.info("Terminated #{params[:provider]} authentication for identity #{current_identity.id} in realm #{realm.label}.")

      "Authorization for provider #{params[:provider]} terminated."
  end


  get '/auth/:provider/callback' do
    auth = request.env['omniauth.auth']
    realm = Realm.find_by_label(request.env['omniauth.strategy'].options[:realm])
    return render_error unless realm

    auth['realm_id'] = realm.id

    # let's see what comes back so we can write some tests
    # File.open('tmp/auth_data.txt', 'w') do |f|
    #   f.write auth.inspect
    # end

    # NOTE: only handling twitter, and not dealing with any merging
    # also, 'establish' might be the wrong name for this, and it's probably doing too much.
    Account.find_or_create_with_auth_data(auth) do |account|
      account.promote_to(Species::User)
      account.identity.touch(:active_at)
    end

    # Enque info update jobs for user

    # Reset temporary auth cookie
    # session[:auth_app_id] = nil

    # Set current user
    # self.current_user = @user

    # flash[:success] = t("auth.success",
    #   :app_title => realm.title,
    #   :provider => @auth_data['provider'].capitalize)

    # @@logger.info(
    #   "Authenticated user ##{@user.id}, " <<
    #   "#{@user.name} for #{@provider}. " <<
    #   "#{@user.enrolled_by_user ? "Enrolled by #{@user.enrolled_by_user.name}": ""}"
    # )

    # render_success



    # do whatever you want with the information!
    "realm: #{realm.inspect}! oh look: #{auth.inspect}"
  end
end
