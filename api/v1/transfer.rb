require 'uri'

class CheckpointV1 < Sinatra::Base

  helpers do
    def url_with_query_params(url, params)
      uri = URI.parse(url)
      uri.query << "&" if uri.query
      uri.query ||= ''
      params.each do |key, value|
        uri.query << CGI.escape(key.to_s)
        uri.query << '='
        uri.query << CGI.escape(value.to_s)
        uri.query << '&'
      end
      uri.to_s
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