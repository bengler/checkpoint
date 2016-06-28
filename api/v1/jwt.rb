class CheckpointV1 < Sinatra::Base

  class PrivateKeyNotFoundError < StandardError
  end

  JWT_TTL = 5.minutes

  JWT_PRIVATE_KEYS = {}
  Dir.glob('./config/jwt_private_keys/*.pem').each{ |priv_key|
    filename = priv_key.split('/')[-1]
    realm = filename.split('_')[0].to_sym
    env = filename.split('_')[1].split('.')[0].to_sym
    JWT_PRIVATE_KEYS[env] ||= {}
    JWT_PRIVATE_KEYS[env][realm] = OpenSSL::PKey::RSA.new File.read(priv_key).to_s
  }

  # @apidoc
  # Issue JSON web token for current identity
  #
  # @category Checkpoint/JSON Web tokens
  # @path /api/checkpoint/v1/identities/me/jwt
  # @example /api/checkpoint/v1/identities/me/jwt
  # @http GET
  # @status 200 [JSON]

  get '/identities/me/jwt' do
    identity = current_identity
    if identity.nil? or identity.realm.id != current_realm.id
      halt 200, {'Content-Type' => 'application/json'}, "{}"
    end
    jwt = begin
      issue_web_token(identity)
    rescue PrivateKeyNotFoundError
      halt 500, {:error => {:message => "No private key found for realm '#{identity.realm.label}'. Unable to issue token."}}.to_json
    end
    pg :jwt, :locals => {:jwt => jwt}
  end


  helpers do

    def issue_web_token(identity)
      account = identity.primary_account
      identity_string = "#{account.provider}:#{account.uid}"
      claim = {
        i: identity_string,
        x: (Time.now+JWT_TTL).to_i
      }
      priv_key = JWT_PRIVATE_KEYS[ENV['RACK_ENV'].to_sym][identity.realm.label.to_sym]
      unless priv_key
        raise PrivateKeyNotFoundError
      end
      jws = JSON::JWT.new(claim).sign(priv_key, :RS256)
      jws.to_s
    end

  end

end
