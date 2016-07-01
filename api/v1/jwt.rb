require 'json/jwt'
require 'base64'

class CheckpointV1 < Sinatra::Base

  class PrivateKeyNotFoundError < StandardError
  end

  class PublicKeyNotFoundError < StandardError
  end

  JWT_TTL = 5.minutes

  JWT_PRIVATE_KEYS = {}

  Dir.glob('./config/jwt_private_keys/*.pem').each{ |file|
    file_handle = file.split('/')[-1]
    realm = file_handle.split('_')[0].to_sym
    env = file_handle.split('_')[1].split('.')[0].to_sym
    JWT_PRIVATE_KEYS[env] ||= {}
    JWT_PRIVATE_KEYS[env][realm] = OpenSSL::PKey::RSA.new File.read(file).to_s
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
    pg :jwt, :locals => {:jwt => jwt, :realm => identity.realm.label}
  end


  helpers do

    def issue_web_token(identity)
      account = identity.primary_account
      identity_string = "#{account.provider}::#{account.uid}::#{identity.id}"
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

    def identity_from_jwt(token)
      return nil unless token
      identity_id = Base64.strict_decode64(token['i']).split('::').last
      @identity_from_jwt ||= Identity.find(identity_id)
    end

    def current_json_web_token
      @current_json_web_token ||= begin
        token = bearer_token
        if token
          realm = realm_header
          halt 500, {:message => "Missing 'Checkpoint-Realm' header"}.to_json unless realm
          decoded = begin
            JSON::JWT.decode(token, JWT_PRIVATE_KEYS[ENV['RACK_ENV'].to_sym][realm.to_sym])
          rescue JSON::JWS::VerificationFailed => e
            halt 403, {:message => "Token verification failed"}.to_json
          end
          expired = Time.at(decoded['x']) < (Time.now-JWT_TTL)
          halt 401, {:message => "Token has expired"}.to_json if expired
          decoded
        end
      end
    end

    def bearer_token
      pattern = /^Bearer /
      header  = request.env['HTTP_AUTHORIZATION']
      header.gsub(pattern, '') if header && header.match(pattern)
    end

    def realm_header
      request.env['HTTP_CHECKPOINT_REALM']
    end

  end

end
