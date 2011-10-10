class CheckpointV1 < Sinatra::Base

  get '/:realm/auth/:provider' do
    realm = Realm.find_by_label(params[:realm])
    halt 404, "Unknown realm #{params[:realm]}" unless realm
    session[:realm] = params[:realm]
    redirect to("/auth/#{params[:provider]}")    
  end

  # This is called directly by Omniauth to allow us to setup
  # the strategy. Unfortunately I did not find a way to 
  # provide the realm with the url, so this is passed through
  # the session. Yuck!  
  get '/auth/:provider/setup' do
    strategy = request.env['omniauth.strategy']
    realm = Realm.find_by_label(session[:realm])
    service_keys = realm.external_service_keys[params[:provider].to_sym]    

    # OmniAuth Strategies are implemented either as consumers (oAuth) or
    # as clients (Facebook etc.), so check what this strategy responds_to

    if strategy.respond_to?(:consumer_key) # This is Oauth
      strategy.consumer_key = service_keys[:client_id]
      strategy.consumer_secret = service_keys[:client_secret]
    elsif strategy.respond_to?(:client_id) # This is a "client"
      strategy.client_id = service_keys[:client_id]
      strategy.client_secret = service_keys[:client_secret]
    else
      halt 500, "Invalid strategy for provider: #{params[:provider]}"
    end

    strategy.options[:scope] = service_keys[:scope] if service_keys[:scope]
    
    # NOTE: Additional params can be set here like this:
    strategy.options[:realm] = realm.label

    strategy.options[:callback] = api_path("/#{realm.label}/auth/{params[:provider]}/callback")

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
    account = Account.create_or_update(auth)
    identity = account.ensure_identity!
    

    # Try to create a new user, if not update existing
    begin
      @user = User.create_or_update!(@auth_data, current_user)
    rescue ActiveRecord::RecordNotUnique
      # This uid exist in another user, probably a contact.
      # Merge this user into the current          
      old_user = User.find_by_provider_and_uid(
        @auth_data['provider'], 
        @auth_data['uid']
      )
      if old_user.friend?
        @@enrolled = true
        @@logger.info(
          "Found matching friend user: ##{old_user.id}, " <<
          "#{old_user.name}, merging into current_user ##{@current_user.id}, #{@current_user.name}"
        )
        old_user.person.followers.each{|follower|
          follower.follow!(current_user.person)
          @@logger.debug("#{follower.user.name} is now following #{current_user.name} (#{current_user.id})")
        }
        # Get rid of old friend type user.
        old_user.destroy          
        @user = current_user
      end
    end

    # Set some meta data
    @user.active_at = Time.now
    @user.kind = Species::User if @user.friend?
    @user.save

    # Save authentication
    @auths[@provider].user_id = @user.id
    @auths[@provider].save
  
    # Enque info update jobs for user
    if @user.user_info_remote_updated_at.nil? or (
        @user.user_info_remote_updated_at and 
          @user.user_info_remote_updated_at < (Time.now-User::USER_INFO_OUTDATES_IN)
        )
      Delayed::Job.enqueue(UserInfoUpdateJob.new(@user.id, realm.id), {:priority => 10})
      Delayed::Job.enqueue(UserEventsUpdateJob.new(@user.id, realm.id), {:priority => 10})
    end



    # Reset temporary auth cookie
    session[:auth_app_id] = nil

    # Set current user
    self.current_user = @user

    flash[:success] = t("auth.success",
      :app_title => realm.title,
      :provider => @auth_data['provider'].capitalize)        
          
    @@logger.info(
      "Authenticated user ##{@user.id}, " <<
      "#{@user.name} for #{@provider}. " <<
      "#{@user.enrolled_by_user ? "Enrolled by #{@user.enrolled_by_user.name}": ""}"
    )
    
    render_success      


  
  # do whatever you want with the information!
  "realm: #{realm}! oh look: #{auth.inspect}, #{strategy.options.inspect}"
  

  end
end