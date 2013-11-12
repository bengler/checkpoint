class CheckpointV1 < Sinatra::Base

  # @apidoc
  # Perform all relevant callbacks checking if the provided action is allowed for the current
  # identity. The verdict is returned in the 'allowed' parameter. If the action is disallowed
  # the reason is provided in the 'reason' field and the url of the denying callback will be in
  # the 'url'-field.
  #
  # @category Checkpoint/Callbacks
  # @path /api/checkpoint/v1/callbacks/allowed/:method/:uid
  # @http POST
  # @example /api/checkpoint/v1/callbacks/allowed/create/post.blog:acme.blog
  # @required [String] method One of 'create', 'update', 'delete'
  # @required [String] uid The uid of the object in question
  # @optional [Integer] identity Ask for a specific identity (default: current identity)
  # @optional [String] * Any other parameter provided will be forwarded to each callback for its consideration
  # @status 200 Result hash
  # @status 500 One or more of the callbacks failed, please call again later

  helpers do
    def perform_callback
      params[:identity] ||= current_identity.try(:id)
      params[:session] ||= current_session.key
      params.delete('splat')
      params.delete('captures')
      # Todo: add a test case for this
      if current_identity && current_identity.god && identity.realm == current_realm
        pg :callback_result, :locals => {:allowed => true, :url => request.url, :reason => "You are God!"}
      elsif banned_path = Banning.banned?(params.to_options)
        pg :callback_result, :locals => {:allowed => false, :url => request.url,
          :reason => "This identity is banned from '#{banned_path}'."}
      else
        allowed, url, reason = Callback.allow?(params.to_options)
        pg :callback_result, :locals => {:allowed => allowed, :url => url, :reason => reason}
      end
    end
  end

  get "/callbacks/allowed/:method/:uid" do
    LOGGER.warn "#{request.referrer} used GET to invoke callbacks. This is deprecated. Use POST."
    perform_callback
  end

  post "/callbacks/allowed/:method/:uid" do
    perform_callback
  end

  # @apidoc
  # Get all callbacks for the current realm. Requires god permissions.
  #
  # @category Checkpoint/Callbacks
  # @path /api/checkpoint/v1/callbacks
  # @http GET
  # @example /api/checkpoint/v1/callbacks
  # @status 200 [Collection of callbacks]
  # @status 403 You are not god

  get "/callbacks" do
    check_god_credentials
    pg :callbacks, :locals => {:callbacks => Callback.order('callbacks.id desc').of_realm(current_realm)}
  end

  # @apidoc
  # Get a specific callback. Requires god permissions.
  #
  # @category Checkpoint/Callbacks
  # @path /api/checkpoint/v1/callbacks/:id
  # @http GET
  # @example /api/checkpoint/v1/callbacks/1
  # @status 200 [Attributes of callback]
  # @status 403 You are not god

  get "/callbacks/:id" do
    callback = Callback.find(params[:id])
    check_god_credentials(callback.realm.id)
    pg :callback, :locals => { :callback => callback }
  end

  # @apidoc
  # Create a callback. Requires god permissions.
  #
  # @note This method does nothing if a callback allready exists for the provided params.
  # @category Checkpoint/Callbacks
  # @path /api/checkpoint/v1/callbacks
  # @http POST
  # @example /api/checkpoint/v1/callbacks
  # @required [String] callback.path The path the callback shall protect.
  # @required [String] callback.url The url which will allow/disallow an action.
  # @status 201 [Attributes of callback]
  # @status 403 You are not god
  # @status 404 No such realm
  # @status 400 You forgot to namespace your record - or, there were no attributes

  post "/callbacks" do
    attributes = params[:callback]
    halt 400, "Please remember to namespace your records" if attributes.nil?
    realm_label = attributes[:path].split('.').first
    realm = Realm.find_by_label(realm_label)
    halt 404, "No such realm (#{realm_label})" unless realm
    check_god_credentials(realm.id)

    status = 200
    callback = Callback.where(:path => attributes[:path], :url => attributes[:url]).first
    unless callback
      callback = Callback.create!(
        :path => attributes[:path],
        :url => attributes[:url])
      status = 201
    end
    [status, pg(:callback, :locals => { :callback => callback })]
  end

  # @apidoc
  # Delete a specific callback. Requires god permissions.
  #
  # @category Checkpoint/Callbacks
  # @path /api/checkpoint/v1/callbacks/:id
  # @http DELETE
  # @example /api/checkpoint/v1/callbacks/1
  # @status 200 [Attributes of former callback]
  # @status 403 You are not god

  delete "/callbacks/:id" do
    callback = Callback.find(params[:id])
    check_god_credentials(callback.realm.id)
    callback.destroy
    pg :callback, :locals => { :callback => callback }
  end
end