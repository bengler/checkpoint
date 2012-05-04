require 'uri'

class CheckpointV1 < Sinatra::Base

  helpers do
    def parse_url(url)
      parsed = URI.parse(url)
      parsed.host ||= request.host
      parsed.scheme ||= request.scheme
      parsed.port ||= request.port
      parsed
    rescue URI::InvalidURIError
      halt 400, "Invalid URL #{url.inspect}"
    end

    # Checks that the provided host-name is attached to the current realm
    def check_domain_is_within_current_realm(domain_name)
      domain = Domain.resolve_from_host_name(domain_name)
      halt 403, "No realm configured for domain #{domain_name}" unless domain
      halt 400, "No origin realm for #{request.host}" unless current_realm
      halt 403, "#{domain_name} is not attached to the realm '#{current_realm.label}'." unless domain.realm_id == current_realm.id
      true
    end
  end

  # Redirect safely to any domain within the realm while preserving the session. 
  # Requires that both the origin domain and target domain is attached to the same
  # realm. This method falls back to a common redirect if the origin and target domain 
  # is the same.
  #
  # @param [String] target Url to redirect to
  get '/transfer' do
    target_url = parse_url(params[:target])

    # Are we leaving or arriving?
    if request.host != target_url.host
      # We are leaving the origin domain
      check_domain_is_within_current_realm(target_url.host)

      new_url = target_url.dup
      new_url.path = '/api/checkpoint/v1/transfer'
      redirect url_with_query_params(new_url.to_s,
        :target => target_url.to_s,
        :session => current_session.key)
    else
      # We have arrived at the target domain
      set_session_key(params[:session]) if params[:session]
      redirect target_url.to_s
    end
  end

  # Create a transfer token. This can be used to transfer a session cookie securely
  # from one domain to another.
  #
  # This generates a public, secure token that can be used with /transfer/:token. It
  # also generates a secret that can be used to later check the validity of the
  # transfer redirect.
  #
  # The token is only valid for a short time (approximately 5 minutes).
  #
  # @returns [JSON]
  #
  post '/transfer/token', :provides => :json do
    token = TransferToken.generate(request.referrer)
    [201, pg(:transfer_token, :locals => {:transfer_token => token})]
  end

  # Use a transfer token. This will always redirect back to the URL specified 
  # in the 'return_url' parameter (or the referrer is none is specified), with 
  # a session key in 'session_key' and a signature in 'signature'.
  #
  # If the transfer fails, the redirect returns with a 'error' parameter set
  # to a machine-readable string.
  #
  # The signature function is:
  #
  #   signature = base64(HMAC_SHA256(secret, session_key))
  #
  # In Ruby:
  #
  #   Base64.encode64(
  #     OpenSSL::HMAC.digest(
  #       OpenSSL::Digest::SHA256.new, secret, session_key)).strip
  #
  # It must be validated by the receiving end and rejected if it does not match,
  # as this implies that the sender is not the original transfer endpoint.
  #
  # @param [String] return_url Where to redirect (optional)
  #
  get '/transfer/:token' do |token_value|
    return_url = params[:return_url] || request.referrer
    unless return_url
      halt 500, "Missing return URL"
    end

    token = TransferToken.find(token_value)
    unless token
      redirect url_with_query_params(return_url, :error => :invalid_token)
    end
    unless token.valid_referrer?(request.referrer) and token.valid_referrer?(return_url)
      redirect url_with_query_params(return_url, :error => :invalid_return)
    end

    redirect url_with_query_params(return_url,
      :session_key => current_session.key,
      :signature => token.sign_with_secret(current_session.key))
  end

end